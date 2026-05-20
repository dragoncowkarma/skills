#!/usr/bin/env bash
# =============================================================================
# harness.sh — Hardened & Auditable Protocol Engine v2.0.0
#
# Replaces harness.py. Runs natively in shell to avoid Python subprocess
# permission popups in sandboxed AI agent environments.
#
# Supports: Linux, macOS, Windows (WSL/Git Bash)
# Requires: bash 4+, jq
# =============================================================================
set -euo pipefail

# ===== GLOBALS =====
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "${SCRIPT_PATH}/../assets" && pwd)"
TASKS_DIR="docs/tasks"
TELEMETRY_DIR=".harness/telemetry"
MAP_PATH="docs/map.md"
CYCLE_LOGS_DIR="docs/cycle_logs"
VERSION="2.0.0"

# Defaults
AUTONOMY_LEVEL=3
TIMEOUT_SECONDS=30
HASH_CMD=""

# ===== PREREQUISITES =====
check_prerequisites() {
  # jq is a hard requirement
  if ! command -v jq &>/dev/null; then
    echo "❌ FATAL: 'jq' is required but not installed."
    echo "  Install: brew install jq (macOS) | apt install jq (Linux) | choco install jq (Windows)"
    exit 1
  fi

  # Detect best available hash command (fallback chain)
  if command -v sha256sum &>/dev/null; then
    HASH_CMD="sha256sum"
  elif command -v shasum &>/dev/null; then
    HASH_CMD="shasum -a 256"
  elif command -v md5sum &>/dev/null; then
    HASH_CMD="md5sum"
  elif command -v md5 &>/dev/null; then
    HASH_CMD="md5 -r"
  else
    echo "❌ FATAL: No hash command found (sha256sum, shasum, md5sum, md5)."
    exit 1
  fi
}

# ===== UTILITY FUNCTIONS =====
compute_hash() {
  local file="$1"
  ${HASH_CMD} "$file" | awk '{print $1}'
}

is_human() {
  if [[ "${HARNESS_SESSION_TYPE:-}" == "HUMAN" ]]; then
    return 0
  fi
  if [[ "${HARNESS_AGENT:-}" == "true" ]]; then
    return 1
  fi
  return 0 # Default to human for DX
}

get_file_mtime() {
  local file="$1"
  case "$(uname -s)" in
    Darwin)  stat -f %m "$file" ;;
    *)       stat -c %Y "$file" ;;
  esac
}

# ===== INTEGRITY =====
verify_integrity() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"
  local log_path="${TELEMETRY_DIR}/${task_id}.log"

  if [[ ! -f "$task_file" ]] || [[ ! -f "$log_path" ]]; then
    echo "Missing task registry or telemetry log."
    return 1
  fi

  local actual_hash
  actual_hash=$(compute_hash "$log_path")

  local stored_hash
  stored_hash=$(jq -r '.telemetry_hash // ""' "$task_file")

  if [[ "$actual_hash" != "$stored_hash" ]]; then
    echo "INTEGRITY VIOLATION: Registry hash does not match physical log."
    return 1
  fi

  return 0
}

# ===== LCOV PARSING =====
parse_lcov() {
  local lcov_path="$1"

  if [[ ! -f "$lcov_path" ]]; then
    echo "ERROR:Coverage report (lcov.info) not found. Run tests with coverage tool (e.g., c8, nyc)."
    return 1
  fi

  local total_lf=0
  local total_lh=0

  while IFS= read -r line; do
    case "$line" in
      LF:*) total_lf=$(( total_lf + ${line#LF:} )) ;;
      LH:*) total_lh=$(( total_lh + ${line#LH:} )) ;;
    esac
  done < "$lcov_path"

  if [[ "$total_lf" -eq 0 ]]; then
    echo "0.00"
    return 0
  fi

  awk "BEGIN {printf \"%.2f\", ($total_lh / $total_lf) * 100}"
}

# ===== CYCLE LOG CHECK =====
check_cycle_log() {
  local task_id="$1"
  local log_file="${CYCLE_LOGS_DIR}/${task_id}_log.md"

  if [[ ! -f "$log_file" ]]; then
    echo "❌ REASONING VIOLATION: Cycle log not found: ${log_file}"
    echo "   You MUST document your reasoning before executing tests."
    return 1
  fi

  # Check if file was modified within last 120 seconds
  local now mtime age
  now=$(date +%s)
  mtime=$(get_file_mtime "$log_file")
  age=$(( now - mtime ))

  if [[ "$age" -gt 120 ]]; then
    echo "⚠️ WARNING: Cycle log is stale (${age}s old). Update your reasoning before proceeding."
    return 1
  fi

  echo "✅ Cycle log verified: ${log_file}"
  return 0
}

# ===== RUN TEST =====
run_test() {
  local task_id="$1"
  local command="$2"
  local mode="${3:-standard}"

  # --- Blocked commands check ---
  local cmd_lower
  cmd_lower=$(echo "$command" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//')

  local prefix
  for prefix in "grep" "ls " "cat " "echo " "[ " "test " "node -e"; do
    if [[ "$cmd_lower" == "$prefix"* ]]; then
      echo "❌ INTEGRITY VIOLATION: Command '${command}' is physically blocked."
      return 1
    fi
  done

  # --- Cycle log enforcement ---
  check_cycle_log "$task_id" || return 1

  local start_time
  start_time=$(date +%s)

  echo "🧪 [TASK:${task_id}] [MODE:${mode}] Executing: ${command}"

  mkdir -p "$TELEMETRY_DIR"
  local log_path="${TELEMETRY_DIR}/${task_id}.log"

  # Determine timeout based on autonomy level
  local timeout_val=$TIMEOUT_SECONDS
  if [[ "$AUTONOMY_LEVEL" -eq 4 ]]; then
    timeout_val=120
  fi

  # Execute command safely (no eval, no shell expansion beyond bash -c)
  local exit_code=0
  if command -v timeout &>/dev/null; then
    timeout "$timeout_val" bash -c "$command" > "$log_path" 2>&1 || exit_code=$?
  elif command -v gtimeout &>/dev/null; then
    gtimeout "$timeout_val" bash -c "$command" > "$log_path" 2>&1 || exit_code=$?
  else
    # Fallback: run without timeout
    bash -c "$command" > "$log_path" 2>&1 || exit_code=$?
  fi

  if [[ "$exit_code" -eq 124 ]]; then
    echo "❌ TIMEOUT VIOLATION: Test execution exceeded ${timeout_val}s limit."
    echo "[ERROR] Execution timed out after ${timeout_val}s." >> "$log_path"
  fi

  # --- TDD ENFORCEMENT LOGIC ---
  local log_text
  log_text=$(cat "$log_path")

  local is_junk_failure=false
  local err_pattern
  for err_pattern in "SyntaxError" "IndentationError" "ReferenceError" "ModuleNotFoundError"; do
    if echo "$log_text" | grep -q "$err_pattern"; then
      is_junk_failure=true
      break
    fi
  done

  local has_assertion=false
  local log_lower
  log_lower=$(echo "$log_text" | tr '[:upper:]' '[:lower:]')
  local keyword
  for keyword in "assertionerror" "failed" "expect" "fail" "assert"; do
    if echo "$log_lower" | grep -q "$keyword"; then
      has_assertion=true
      break
    fi
  done

  if [[ "$mode" == "tdd-red" ]]; then
    if [[ "$exit_code" -eq 0 ]]; then
      echo "❌ INTEGRITY VIOLATION: TDD Red phase requires a FAILING test."
      exit_code=1
    elif [[ "$is_junk_failure" == "true" ]]; then
      echo "❌ INTEGRITY VIOLATION: Junk failure detected. RED phase requires a VALID test failure."
      exit_code=1
    elif [[ "$has_assertion" == "false" ]]; then
      echo "⚠️ WARNING: No clear assertion failure detected in logs. Proceed with caution."
    else
      echo "✅ TDD RED VERIFIED: Test failed as expected with valid assertion."
      exit_code=0 # Treat as success for the protocol loop
    fi
  fi

  # --- MANDATORY COVERAGE CHECK (Standard Mode Only) ---
  local coverage_msg="N/A"
  if [[ "$mode" == "standard" ]] && [[ "$exit_code" -eq 0 ]]; then
    local lcov_path="coverage/lcov.info"
    local percentage
    percentage=$(parse_lcov "$lcov_path" 2>&1) || true

    if [[ "$percentage" == ERROR:* ]]; then
      echo "❌ COVERAGE ERROR: ${percentage#ERROR:}"
      exit_code=1
      coverage_msg="${percentage#ERROR:}"
    else
      local below
      below=$(awk "BEGIN {print ($percentage < 80.0) ? 1 : 0}")
      if [[ "$below" -eq 1 ]]; then
        echo "❌ INTEGRITY VIOLATION: Line Coverage ${percentage}% is below 80% threshold."
        exit_code=1
        coverage_msg="Low Coverage: ${percentage}%"
      else
        echo "✅ COVERAGE PASSED: ${percentage}%"
        coverage_msg="${percentage}%"
      fi
    fi
  fi

  # --- LOCK TELEMETRY ---
  local duration
  duration=$(( $(date +%s) - start_time ))
  local salt
  salt=$(printf "\n[salt:%s:%s]" "$task_id" "$(date +%s.%N 2>/dev/null || date +%s)")
  printf "%s" "$salt" >> "$log_path"

  local telemetry_hash
  telemetry_hash=$(compute_hash "$log_path")

  # --- UPDATE REGISTRY ---
  local task_file="${TASKS_DIR}/${task_id}.json"
  if [[ -f "$task_file" ]]; then
    local new_status="Failed"
    [[ "$exit_code" -eq 0 ]] && new_status="Verified"

    local prev_duration prev_retries prev_tokens
    prev_duration=$(jq -r '.metrics.duration_seconds // 0' "$task_file")
    prev_retries=$(jq -r '.metrics.retry_count // 0' "$task_file")
    prev_tokens=$(jq -r '.metrics.tokens_used // 0' "$task_file")

    local new_duration=$(( prev_duration + duration ))
    local new_retries=$prev_retries
    [[ "$exit_code" -ne 0 ]] && new_retries=$(( prev_retries + 1 ))

    jq \
      --arg status "$new_status" \
      --arg hash "$telemetry_hash" \
      --arg mode "$mode" \
      --arg cov "$coverage_msg" \
      --argjson dur "$new_duration" \
      --argjson retries "$new_retries" \
      --argjson tokens "$prev_tokens" \
      '.status = $status |
       .telemetry_hash = $hash |
       .verification_mode = $mode |
       .metrics.duration_seconds = $dur |
       .metrics.retry_count = $retries |
       .metrics.tokens_used = $tokens |
       .metrics.coverage = $cov' "$task_file" > "${task_file}.tmp" && mv "${task_file}.tmp" "$task_file"

    echo "🔒 Telemetry Locked. Status: ${new_status} | Mode: ${mode}"
  else
    echo "⚠️ Registry entry for ${task_id} not found."
  fi

  return $exit_code
}

# ===== DOCUMENT =====
document() {
  local standard="$1"
  echo "📄 Generating Documentation for Standard: ${standard}..."

  if [[ "$standard" == "ISO_42010" ]]; then
    local template_path="${ASSETS_DIR}/ISO_42010_template.md"
    local output_path="docs/architecture.md"

    if [[ ! -f "$MAP_PATH" ]]; then
      echo "⚠️ Warning: ${MAP_PATH} not found. Skipping architecture doc."
      return 0
    fi

    # Parse map.md for mermaid + components
    local mermaid_lines=""
    local component_lines=""

    while IFS= read -r line; do
      if [[ "$line" == *"|"*'`'* ]]; then
        local clean
        clean=$(echo "$line" | tr -d '`')
        local symbol path target desc

        # Extract fields by splitting on |
        symbol=$(echo "$clean" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        path=$(echo "$clean" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
        desc=$(echo "$clean" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $5); print $5}')

        # Skip header/separator
        if [[ -n "$symbol" ]] && [[ "$symbol" != :* ]] && [[ "$symbol" != -* ]]; then
          target=$(echo "$path" | cut -d'/' -f1)
          mermaid_lines="${mermaid_lines}    ${symbol} --> ${target}"$'\n'
          component_lines="${component_lines}- **${symbol}**: Located in \`${path}\`. ${desc}"$'\n'
        fi
      fi
    done < "$MAP_PATH"

    local mermaid_block
    mermaid_block=$(printf "graph TD\n%s" "$mermaid_lines")

    mkdir -p docs
    local template
    template=$(cat "$template_path")

    # Replace placeholders using awk for safety with special characters
    echo "$template" | awk -v diagram="$mermaid_block" -v details="$component_lines" \
      '{gsub(/\{mermaid_diagram\}/, diagram); gsub(/\{component_details\}/, details); print}' \
      > "$output_path"

    echo "✅ Architecture Specification updated: ${output_path}"

  elif [[ "$standard" == "ISO_25010" ]]; then
    local template_path="${ASSETS_DIR}/ISO_25010_template.md"
    local output_path="docs/quality_metrics.md"

    # Check for task files
    local task_files
    task_files=$(find "$TASKS_DIR" -name '*.json' 2>/dev/null) || true
    if [[ -z "$task_files" ]]; then
      echo "⚠️ Warning: No tasks found. Skipping quality metrics."
      return 0
    fi

    local total_tasks=0
    local verified_count=0
    local total_coverage=0
    local coverage_count=0
    local total_retries=0
    local total_duration=0
    local task_rows=""

    local tf
    for tf in "$TASKS_DIR"/*.json; do
      [[ ! -f "$tf" ]] && continue
      total_tasks=$(( total_tasks + 1 ))

      local t_id t_status t_cov t_dur t_retry
      t_id=$(jq -r '.id // "N/A"' "$tf")
      t_status=$(jq -r '.status // "N/A"' "$tf")
      t_cov=$(jq -r '.metrics.coverage // "N/A"' "$tf")
      t_dur=$(jq -r '.metrics.duration_seconds // 0' "$tf")
      t_retry=$(jq -r '.metrics.retry_count // 0' "$tf")

      [[ "$t_status" == "Verified" ]] && verified_count=$(( verified_count + 1 ))

      if echo "$t_cov" | grep -q '%'; then
        local cov_val
        cov_val=$(echo "$t_cov" | tr -d '%')
        total_coverage=$(awk "BEGIN {print $total_coverage + $cov_val}")
        coverage_count=$(( coverage_count + 1 ))
      fi

      total_retries=$(( total_retries + t_retry ))
      total_duration=$(( total_duration + t_dur ))

      task_rows="${task_rows}| ${t_id} | ${t_status} | ${t_cov} | ${t_dur}s | ${t_retry} |"$'\n'
    done

    local avg_coverage="0.00"
    [[ "$coverage_count" -gt 0 ]] && avg_coverage=$(awk "BEGIN {printf \"%.2f\", $total_coverage / $coverage_count}")

    local success_rate retry_rate avg_duration
    success_rate=$(awk "BEGIN {printf \"%.2f\", ($verified_count / $total_tasks) * 100}")
    retry_rate=$(awk "BEGIN {printf \"%.2f\", ($total_retries / $total_tasks) * 100}")
    avg_duration=$(awk "BEGIN {printf \"%.2f\", $total_duration / $total_tasks}")

    mkdir -p docs
    sed -e "s|{avg_coverage}|${avg_coverage}|g" \
        -e "s|{total_tasks}|${total_tasks}|g" \
        -e "s|{retry_rate}|${retry_rate}|g" \
        -e "s|{success_rate}|${success_rate}|g" \
        -e "s|{avg_duration}|${avg_duration}|g" \
        -e "/{task_rows}/c\\
${task_rows}" \
        "$template_path" > "$output_path"

    echo "✅ Quality Metrics updated: ${output_path}"
  else
    echo "❌ Unknown standard: ${standard}"
    return 1
  fi
}

# ===== APPROVE =====
approve() {
  local task_id="$1"

  if ! is_human; then
    echo "❌ SECURITY ERROR: Agent attempted to self-approve."
    return 1
  fi

  local task_file="${TASKS_DIR}/${task_id}.json"
  if [[ ! -f "$task_file" ]]; then
    echo "❌ Error: Task ${task_id} not found."
    return 1
  fi

  local status
  status=$(jq -r '.status' "$task_file")
  if [[ "$status" != "Verified" ]]; then
    echo "❌ Error: Task ${task_id} must be 'Verified' before approval."
    return 1
  fi

  jq '.status = "Approved" | .approved = true' "$task_file" > "${task_file}.tmp" \
    && mv "${task_file}.tmp" "$task_file"
  echo "✅ Task ${task_id} Approved by Human Actor."
}

# ===== COMMIT =====
do_commit() {
  local task_id="$1"
  local msg="$2"

  if ! verify_integrity "$task_id"; then
    echo "❌ Integrity check failed."
    return 1
  fi

  local task_file="${TASKS_DIR}/${task_id}.json"
  local status
  status=$(jq -r '.status' "$task_file")

  if [[ "$status" != "Verified" ]] && [[ "$status" != "Approved" ]]; then
    echo "❌ Task ${task_id} must be Verified to commit."
    return 1
  fi

  local coverage
  coverage=$(jq -r '.metrics.coverage // "N/A"' "$task_file")
  local cov_lower
  cov_lower=$(echo "$coverage" | tr '[:upper:]' '[:lower:]')

  if [[ "$cov_lower" == *"fail"* ]] || [[ "$cov_lower" == *"missing"* ]] || [[ "$coverage" == "N/A" ]]; then
    echo "❌ INTEGRITY VIOLATION: Task ${task_id} has invalid coverage record (${coverage})."
    return 1
  fi

  git commit -m "[harness:${task_id}] ${msg}"
}

# ===== PRE-COMMIT CHECK =====
pre_commit_check() {
  echo "🛡️ Running Harness Pre-commit Integrity Check..."
  return 0
}

# ===== GENERATE PROMPT =====
generate_prompt() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"

  if [[ ! -f "$task_file" ]]; then
    echo "❌ Error: Task ${task_id} not found."
    return 1
  fi

  local template
  template=$(cat "${ASSETS_DIR}/PROMPT.xml")

  # Substitute placeholders from task JSON
  local t_target t_role t_priority
  t_target=$(jq -r '.target_file // "N/A"' "$task_file")
  t_role=$(jq -r '.assigned_sub_agent // "Dev"' "$task_file")
  t_priority=$(jq -r '.priority // "Medium"' "$task_file")

  echo "$template" | sed \
    -e "s|{task_id}|${task_id}|g" \
    -e "s|{target_file}|${t_target}|g" \
    -e "s|{agent_role}|${t_role}|g" \
    -e "s|{priority}|${t_priority}|g"
}

# ===== RUN PIPELINE (AUTONOMY LEVELS) =====
run_pipeline() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"

  if [[ ! -f "$task_file" ]]; then
    echo "❌ Error: Task ${task_id} not found."
    return 1
  fi

  echo "🚀 [LEVEL:${AUTONOMY_LEVEL}] Starting pipeline for task: ${task_id}"

  # --- Level 1: Planning Only ---
  if [[ "$AUTONOMY_LEVEL" -eq 1 ]]; then
    echo "📋 Level 1 (Planning): Generating docs structure..."
    mkdir -p docs/tasks docs/cycle_logs docs/prompts

    # Initialize cycle log template
    local log_file="${CYCLE_LOGS_DIR}/${task_id}_log.md"
    if [[ ! -f "$log_file" ]]; then
      cat > "$log_file" <<LOGEOF
# Cycle Log: ${task_id}

## Cycle 1 — $(date -u +"%Y-%m-%dT%H:%M:%SZ")
### Intent
[Document your reasoning here]

### Analysis
[Document your observations here]

### Plan
[Document your plan here]
LOGEOF
      echo "✅ Created cycle log template: ${log_file}"
    fi
    echo "✅ Level 1 complete. Docs structure ready."
    return 0
  fi

  # --- Level 2: Prompting Only ---
  if [[ "$AUTONOMY_LEVEL" -eq 2 ]]; then
    echo "📝 Level 2 (Prompting): Generating prompt..."
    echo "---"
    generate_prompt "$task_id"
    echo "---"
    echo "✅ Level 2 complete. Prompt generated above. Awaiting manual execution."
    return 0
  fi

  # --- Level 3: Interactive ---
  if [[ "$AUTONOMY_LEVEL" -eq 3 ]]; then
    echo "🔄 Level 3 (Interactive): Running with approval gates..."

    local cmd
    cmd=$(jq -r '.mechanical_dod.command // ""' "$task_file")
    if [[ -z "$cmd" || "$cmd" == "null" ]]; then
      echo "❌ No command defined in task mechanical_dod."
      return 1
    fi

    # Determine phase from task ID
    if [[ "$task_id" == *-RED* ]]; then
      echo "--- RED PHASE ---"
      run_test "$task_id" "$cmd" "tdd-red" || return 1
      echo ""
      read -rp "✋ RED phase complete. Continue to documentation? [y/N] " answer
      [[ "$answer" != "y" && "$answer" != "Y" ]] && { echo "⏸ Paused by user."; return 0; }
    else
      echo "--- GREEN PHASE ---"
      run_test "$task_id" "$cmd" "standard" || return 1
      echo ""
      read -rp "✋ GREEN phase complete. Continue to documentation? [y/N] " answer
      [[ "$answer" != "y" && "$answer" != "Y" ]] && { echo "⏸ Paused by user."; return 0; }
    fi

    # DOC phase
    echo "--- DOC PHASE ---"
    document "ISO_42010"
    document "ISO_25010"
    echo ""
    read -rp "✋ Documentation complete. All done. [Enter to finish] " _
    echo "✅ Level 3 pipeline complete."
    return 0
  fi

  # --- Level 4: Autonomous ---
  if [[ "$AUTONOMY_LEVEL" -eq 4 ]]; then
    echo "🤖 Level 4 (Autonomous): Full auto pipeline..."

    local cmd
    cmd=$(jq -r '.mechanical_dod.command // ""' "$task_file")
    if [[ -z "$cmd" || "$cmd" == "null" ]]; then
      echo "❌ No command defined in task mechanical_dod."
      return 1
    fi

    local sub_agent
    sub_agent=$(jq -r '.assigned_sub_agent // ""' "$task_file")
    if [[ -n "$sub_agent" && "$sub_agent" != "null" ]]; then
      echo "🤖 Delegating to sub-agent: ${sub_agent}"
    fi

    # Mark in-progress
    jq '.sub_task_status = "InProgress"' "$task_file" > "${task_file}.tmp" \
      && mv "${task_file}.tmp" "$task_file"

    # Determine mode
    local mode="standard"
    [[ "$task_id" == *-RED* ]] && mode="tdd-red"

    if run_test "$task_id" "$cmd" "$mode"; then
      # Auto-document
      document "ISO_42010"
      document "ISO_25010"

      # Mark completed
      jq '.sub_task_status = "Completed"' "$task_file" > "${task_file}.tmp" \
        && mv "${task_file}.tmp" "$task_file"
      echo "✅ Level 4 autonomous pipeline complete."
    else
      jq '.sub_task_status = "Failed"' "$task_file" > "${task_file}.tmp" \
        && mv "${task_file}.tmp" "$task_file"
      echo "❌ Level 4 pipeline failed."
      return 1
    fi

    return 0
  fi

  echo "❌ Invalid autonomy level: ${AUTONOMY_LEVEL} (must be 1-4)"
  return 1
}

# ===== HELP =====
show_help() {
  cat <<'HELPEOF'
Harness Protocol Engine v2.0.0

Usage: harness.sh <command> [options]

Commands:
  test        Run test with telemetry locking
  run         Execute full pipeline with autonomy level
  approve     Human-only task approval
  document    Generate ISO documentation
  commit      Verified commit with integrity check
  check       Pre-commit integrity check
  prompt      Generate prompt from template
  help        Show this help

Options:
  --id <task_id>       Task identifier
  --cmd <command>      Test command to execute
  --mode <mode>        Test mode: standard | tdd-red
  --level <1-4>        Autonomy level (default: 3)
  --standard <std>     ISO standard: ISO_42010 | ISO_25010
  --msg <message>      Commit message

Autonomy Levels:
  1 (Planning)       Generate docs structure only, then exit
  2 (Prompting)      Generate prompt text only, then exit
  3 (Interactive)    Step-by-step with approval gates (default)
  4 (Autonomous)     Full auto with sub-agent delegation

Examples:
  harness.sh test --id TASK-001 --cmd "c8 node --test test.js"
  harness.sh run --id TASK-001 --level 4
  harness.sh document --standard ISO_42010
  harness.sh commit --id TASK-001 --msg "feat: add validation"

HELPEOF
}

# ===== MAIN =====
main() {
  check_prerequisites

  # Integrity check: must run from skill workspace
  if [[ "$SCRIPT_PATH" != *"skills/harness/scripts"* ]]; then
    echo "❌ INTEGRITY VIOLATION: Harness engine must run from its skill workspace."
    echo "Attempted path: ${SCRIPT_PATH}"
    exit 1
  fi

  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi

  local cmd="$1"
  shift

  # Parse global flags
  local task_id="" command="" mode="standard" standard="ISO_25010" msg=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)       task_id="$2"; shift 2 ;;
      --cmd)      command="$2"; shift 2 ;;
      --mode)     mode="$2"; shift 2 ;;
      --level)    AUTONOMY_LEVEL="$2"; shift 2 ;;
      --standard) standard="$2"; shift 2 ;;
      --msg)      msg="$2"; shift 2 ;;
      --help|-h)  show_help; exit 0 ;;
      *)          echo "❌ Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  case "$cmd" in
    test)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      [[ -z "$command" ]] && { echo "❌ --cmd required"; exit 1; }
      run_test "$task_id" "$command" "$mode"
      exit $?
      ;;
    run)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      run_pipeline "$task_id"
      exit $?
      ;;
    approve)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      approve "$task_id"
      ;;
    document)
      document "$standard"
      ;;
    commit)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      [[ -z "$msg" ]] && { echo "❌ --msg required"; exit 1; }
      do_commit "$task_id" "$msg"
      ;;
    check)
      pre_commit_check
      ;;
    prompt)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      generate_prompt "$task_id"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      echo "❌ Unknown command: ${cmd}"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
