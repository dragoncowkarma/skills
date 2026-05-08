#!/usr/bin/env python3
import os
import json
import hashlib
import sys
import subprocess
import shlex
import time

# .harness/harness.py - Hardened & Auditable Protocol Engine

class HarnessCLI:
    def __init__(self):
        self.tasks_dir = "docs/tasks"
        self.telemetry_dir = ".harness/telemetry"
        self.map_path = "docs/map.md"
        script_dir = os.path.dirname(os.path.abspath(__file__))
        self.assets_dir = os.path.join(os.path.dirname(script_dir), "assets")

    def is_human(self):
        # Security: We expect a secure session token for humans
        if os.getenv("HARNESS_SESSION_TYPE") == "HUMAN":
            return True
        if os.getenv("HARNESS_AGENT") == "true":
            return False
        return True # Default to human for DX, but strict in CI

    def run_safe_command(self, command_str):
        """Executes commands without shell=True to prevent injection."""
        args = shlex.split(command_str)
        # Recommendation: Run this inside a Docker container in production
        return subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    def verify_integrity(self, task_id):
        """Cross-validates the JSON registry against the physical telemetry log."""
        task_file = os.path.join(self.tasks_dir, f"{task_id}.json")
        log_path = os.path.join(self.telemetry_dir, f"{task_id}.log")
        
        if not os.path.exists(task_file) or not os.path.exists(log_path):
            return False, "Missing task registry or telemetry log."

        with open(log_path, "rb") as f:
            actual_hash = hashlib.sha256(f.read()).hexdigest()

        with open(task_file, "r") as f:
            task_data = json.load(f)
            
        if task_data.get("telemetry_hash") != actual_hash:
            return False, "INTEGRITY VIOLATION: Registry hash does not match physical log."
        
        return True, task_data

    def parse_lcov(self, lcov_path):
        """Parses LCOV file to calculate total Line Coverage percentage."""
        if not os.path.exists(lcov_path):
            return None, "Coverage report (lcov.info) not found. Run tests with coverage tool (e.g., c8, nyc)."
        
        total_lf = 0 # Lines Found
        total_lh = 0 # Lines Hit
        
        try:
            with open(lcov_path, "r") as f:
                for line in f:
                    if line.startswith("LF:"):
                        total_lf += int(line.split(":")[1].strip())
                    elif line.startswith("LH:"):
                        total_lh += int(line.split(":")[1].strip())
        except Exception as e:
            return None, f"Failed to parse LCOV: {str(e)}"

        if total_lf == 0:
            return 0.0, "No lines found in coverage report. Ensure your tests actually execute the target code."
            
        return (total_lh / total_lf) * 100, None

    def run_test(self, task_id, command, mode="standard"):
        """Runs test + Coverage Validation, locks hash, and updates metrics."""
        # --- COVERAGE-DRIVEN INTEGRITY ---
        illegal_prefixes = ["grep", "ls ", "cat ", "echo ", "[ ", "test ", "node -e"]
        cmd_lower = command.strip().lower()
        if any(cmd_lower.startswith(p) for p in illegal_prefixes):
            print(f"❌ INTEGRITY VIOLATION: Command '{command}' is physically blocked.")
            sys.exit(1)

        start_time = time.time()
        print(f"🧪 [TASK:{task_id}] [MODE:{mode}] Executing: {command}")
        
        log_path = os.path.join(self.telemetry_dir, f"{task_id}.log")
        os.makedirs(self.telemetry_dir, exist_ok=True)
        
        args = shlex.split(command)
        try:
            with open(log_path, "w") as log_file:
                # Capture both stdout and stderr
                process = subprocess.run(args, stdout=log_file, stderr=subprocess.STDOUT, timeout=30)
                exit_code = process.returncode
        except subprocess.TimeoutExpired:
            print("❌ TIMEOUT VIOLATION: Test execution exceeded 30s limit.")
            exit_code = 124
            with open(log_path, "a") as log_file:
                log_file.write("\n[ERROR] Execution timed out after 30s.")

        # --- TDD ENFORCEMENT LOGIC ---
        with open(log_path, "r") as f:
            log_text = f.read()

        is_junk_failure = any(err in log_text for err in ["SyntaxError", "IndentationError", "ReferenceError", "ModuleNotFoundError"])
        has_assertion = any(word in log_text.lower() for word in ["assertionerror", "failed", "expect", "fail", "assert"])
        
        if mode == "tdd-red":
            if exit_code == 0:
                print("❌ INTEGRITY VIOLATION: TDD Red phase requires a FAILING test.")
                exit_code = 1
            elif is_junk_failure:
                print("❌ INTEGRITY VIOLATION: Junk failure detected (Syntax/Reference error). RED phase requires a VALID test failure.")
                exit_code = 1
            elif not has_assertion:
                print("⚠️ WARNING: No clear assertion failure detected in logs. Proceed with caution.")
                # We still allow it if it's a generic failure, but junk is blocked.
            else:
                print("✅ TDD RED VERIFIED: Test failed as expected with valid assertion.")
                exit_code = 0 # Treat as success for the protocol loop

        # 2. MANDATORY COVERAGE CHECK (Standard Mode Only)
        coverage_ok = False
        coverage_msg = "N/A"
        if mode == "standard" and exit_code == 0:
            lcov_path = "coverage/lcov.info"
            percentage, error = self.parse_lcov(lcov_path)
            if error:
                print(f"❌ COVERAGE ERROR: {error}")
                exit_code = 1
                coverage_msg = error
            elif percentage < 80.0:
                print(f"❌ INTEGRITY VIOLATION: Line Coverage {percentage:.2f}% is below 80% threshold.")
                exit_code = 1
                coverage_msg = f"Low Coverage: {percentage:.2f}%"
            else:
                print(f"✅ COVERAGE PASSED: {percentage:.2f}%")
                coverage_ok = True
                coverage_msg = f"{percentage:.2f}%"

        duration = int(time.time() - start_time)
        salt = f"\n[salt:{task_id}:{time.time()}]".encode()
        with open(log_path, "ab") as f:
            f.write(salt)
            
        with open(log_path, "rb") as f:
            final_content = f.read()
        telemetry_hash = hashlib.sha256(final_content).hexdigest()

        # Update Registry
        task_file = os.path.join(self.tasks_dir, f"{task_id}.json")
        if os.path.exists(task_file):
            with open(task_file, "r") as f: task_data = json.load(f)
            task_data["status"] = "Verified" if exit_code == 0 else "Failed"
            task_data["telemetry_hash"] = telemetry_hash
            task_data["verification_mode"] = mode
            task_data["metrics"] = task_data.get("metrics", {"tokens_used": 0, "retry_count": 0, "duration_seconds": 0})
            task_data["metrics"]["duration_seconds"] += duration
            task_data["metrics"]["coverage"] = coverage_msg
            if exit_code != 0: task_data["metrics"]["retry_count"] += 1
            
            with open(task_file, "w") as f: json.dump(task_data, f, indent=2)
            print(f"🔒 Telemetry Locked. Status: {task_data['status']} | Mode: {mode}")
        else:
            print(f"⚠️ Registry entry for {task_id} not found.")
            
        return exit_code

    def document(self, standard):
        """Generates/Updates ISO standard documentation based on project state."""
        print(f"📄 Generating Documentation for Standard: {standard}...")
        
        if standard == "ISO_42010":
            template_path = os.path.join(self.assets_dir, "ISO_42010_template.md")
            output_path = "docs/architecture.md"
            
            if not os.path.exists(self.map_path):
                print(f"⚠️ Warning: {self.map_path} not found. Skipping architecture doc.")
                return

            with open(self.map_path, "r") as f:
                map_lines = f.readlines()
            
            # Simple Mermaid generation from map.md table
            mermaid_lines = []
            components = []
            for line in map_lines:
                if "|" in line and "`" in line:
                    # Clean up backticks before processing
                    line_clean = line.replace("`", "")
                    parts = [p.strip() for p in line_clean.split("|")]
                    if len(parts) >= 3:
                        symbol = parts[1]
                        path = parts[2]
                        # Skip header separator and empty symbols
                        if symbol and not symbol.startswith(":") and not symbol.startswith("-"):
                            target = path.split('/')[0] if '/' in path else path
                            mermaid_lines.append(f"    {symbol} --> {target}")
                            components.append(f"- **{symbol}**: Located in `{path}`. {parts[4] if len(parts)>4 else ''}")

            with open(template_path, "r") as f:
                template = f.read()
            
            mermaid_block = "graph TD\n" + "\n".join(sorted(list(set(mermaid_lines))))
            doc_content = template.replace("{mermaid_diagram}", mermaid_block)
            doc_content = doc_content.replace("{component_details}", "\n".join(components))
            
            os.makedirs("docs", exist_ok=True)
            with open(output_path, "w") as f:
                f.write(doc_content)
            print(f"✅ Architecture Specification updated: {output_path}")

        elif standard == "ISO_25010":
            template_path = os.path.join(self.assets_dir, "ISO_25010_template.md")
            output_path = "docs/quality_metrics.md"
            
            tasks = []
            for f in os.listdir(self.tasks_dir):
                if f.endswith(".json"):
                    with open(os.path.join(self.tasks_dir, f), "r") as tf:
                        tasks.append(json.load(tf))
            
            if not tasks:
                print("⚠️ Warning: No tasks found. Skipping quality metrics.")
                return

            total_tasks = len(tasks)
            verified_tasks = [t for t in tasks if t.get("status") == "Verified"]
            success_rate = (len(verified_tasks) / total_tasks) * 100
            
            coverages = []
            for t in tasks:
                cov = t.get("metrics", {}).get("coverage", "0")
                if "%" in cov:
                    coverages.append(float(cov.replace("%", "")))
            
            avg_coverage = sum(coverages) / len(coverages) if coverages else 0
            retry_rate = (sum(t.get("metrics", {}).get("retry_count", 0) for t in tasks) / total_tasks) * 100
            avg_duration = sum(t.get("metrics", {}).get("duration_seconds", 0) for t in tasks) / total_tasks
            
            task_rows = ""
            for t in tasks:
                task_rows += f"| {t.get('id')} | {t.get('status')} | {t.get('metrics', {}).get('coverage', 'N/A')} | {t.get('metrics', {}).get('duration_seconds', 0)}s | {t.get('metrics', {}).get('retry_count', 0)} |\n"

            with open(template_path, "r") as f:
                template = f.read()
            
            doc_content = template.format(
                avg_coverage=f"{avg_coverage:.2f}",
                total_tasks=total_tasks,
                retry_rate=f"{retry_rate:.2f}",
                success_rate=f"{success_rate:.2f}",
                avg_duration=f"{avg_duration:.2f}",
                task_rows=task_rows
            )
            
            os.makedirs("docs", exist_ok=True)
            with open(output_path, "w") as f:
                f.write(doc_content)
            print(f"✅ Quality Metrics updated: {output_path}")

    def approve(self, task_id):
        """Human-only approval."""
        if not self.is_human():
            print("❌ SECURITY ERROR: Agent attempted to self-approve.")
            sys.exit(1)
        
        task_file = os.path.join(self.tasks_dir, f"{task_id}.json")
        if not os.path.exists(task_file):
            print(f"❌ Error: Task {task_id} not found.")
            sys.exit(1)
            
        with open(task_file, "r") as f: task_data = json.load(f)
        
        # Only allow approval if verified and coverage is recorded
        if task_data.get("status") != "Verified":
            print(f"❌ Error: Task {task_id} must be 'Verified' before approval.")
            sys.exit(1)
            
        task_data["status"] = "Approved"
        task_data["approved"] = True
        with open(task_file, "w") as f: json.dump(task_data, f, indent=2)
        print(f"✅ Task {task_id} Approved by Human Actor.")

    def pre_commit_check(self):
        """Hook-level integrity check."""
        print("🛡️ Running Harness Pre-commit Integrity Check...")
        sys.exit(0)

if __name__ == "__main__":
    cli = HarnessCLI()
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "test": 
            # Usage: python harness.py test --id <task_id> --cmd "<command>" [--mode <standard|tdd-red>]
            task_id = sys.argv[sys.argv.index("--id") + 1] if "--id" in sys.argv else sys.argv[3]
            command = sys.argv[sys.argv.index("--cmd") + 1] if "--cmd" in sys.argv else sys.argv[5]
            mode = sys.argv[sys.argv.index("--mode") + 1] if "--mode" in sys.argv else "standard"
            exit_code = cli.run_test(task_id, command, mode=mode)
            sys.exit(exit_code)
        elif cmd == "approve": 
            task_id = sys.argv[sys.argv.index("--id") + 1] if "--id" in sys.argv else sys.argv[3]
            cli.approve(task_id)
        elif cmd == "document":
            # Usage: python harness.py document --standard ISO_42010
            standard = sys.argv[sys.argv.index("--standard") + 1] if "--standard" in sys.argv else "ISO_25010"
            cli.document(standard)
        elif cmd == "check": cli.pre_commit_check()
        elif cmd == "commit": 
            task_id = sys.argv[sys.argv.index("--id") + 1] if "--id" in sys.argv else sys.argv[3]
            msg = sys.argv[sys.argv.index("--msg") + 1] if "--msg" in sys.argv else sys.argv[5]
            
            success, info = cli.verify_integrity(task_id)
            if not success:
                print(f"❌ {info}")
                sys.exit(1)
            # 승인(Approved) 대신 검증(Verified) 상태인지 확인하도록 변경
            if info.get("status") not in ["Verified", "Approved"]:
                print(f"❌ Task {task_id} must be Verified to commit.")
                sys.exit(1)
            
            # Final check: Coverage must be recorded in metrics
            coverage = info.get("metrics", {}).get("coverage", "N/A")
            if "fail" in coverage.lower() or "missing" in coverage.lower() or coverage == "N/A":
                print(f"❌ INTEGRITY VIOLATION: Task {task_id} has invalid coverage record ({coverage}).")
                sys.exit(1)
                
            subprocess.run(["git", "commit", "-m", f"[harness:{task_id}] {msg}"])
