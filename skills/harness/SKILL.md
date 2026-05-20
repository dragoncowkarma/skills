---
name: harness
description: A high-reliability, telemetry-backed autonomous agent protocol with sub-agent delegation, autonomy level control, and mandatory thought-process logging. Implements "Harness-as-a-Protocol" with automated steering and developer-aware actor detection.
license: MIT
metadata:
  author: dragoncowkarma
  version: "2.0.0"
  architecture: "Harness-as-a-Protocol"
---

# `harness` Skill: The Autonomous Protocol

The `harness` skill transforms the repository into a self-regulating "hardware harness" for AI agents. It prioritizes the **Repository as the System of Record (SOR)** and enforces governance through **Mechanical Invariants** and **Automated Steering via Git Hooks**.

## Sub-Agent Workflow

Tasks can be delegated to specialized sub-agents via the `assigned_sub_agent` field in task JSON:

| Sub-Agent | Phase | Scope |
|-----------|-------|-------|
| **QA** | RED | Write failing tests only. Forbidden from production code. |
| **Dev** | GREEN | Implement production code to pass tests. |
| **Doc** | DOCUMENT | Update `docs/` only. Forbidden from `src/` and `tests/`. |

Set `"assigned_sub_agent": null` for single-agent mode (default).

## Autonomy Levels

Control the level of human oversight with `--level`:

| Level | Name | Behavior |
|-------|------|----------|
| 1 | **Planning** | Generate `docs/` structure and cycle log template only, then exit. |
| 2 | **Prompting** | Generate prompt text from `PROMPT.md`, print to stdout, then exit. |
| 3 | **Interactive** | Execute RED→GREEN→DOC loop, pause after each phase for user approval. **(Default)** |
| 4 | **Autonomous** | Full auto loop with sub-agent delegation, no pauses. Timeout extended to 120s. |

```bash
# Example: Run fully autonomous pipeline
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh run --id TASK-001 --level 4
```

## TDD Workflow

To prevent "tautological testing" and hallucination, development must be split into two consecutive tasks:

1.  **RED Task (Adversarial QA)**:
    - **Goal**: Write failing tests based on requirements.
    - **Naming**: `[task_id]-RED.json`.
    - **Execution**: `harness.sh test --mode tdd-red --id [id] --cmd "[cmd]"`.
    - **Constraint**: You are ONLY allowed to modify test files.
    - **Validation**: The engine rejects SyntaxErrors. You must produce a valid `AssertionError`.
2.  **GREEN Task (Implementation Engineer)**:
    - **Goal**: Write production code to satisfy the tests.
    - **Naming**: `[task_id]-GREEN.json`.
    - **Dependency**: Must list the RED task in `depends_on`.
    - **Execution**: Standard `harness.sh test`.
    - **Validation**: Must achieve 80%+ Line Coverage.

## Reasoning Protocol (Cycle Logs)

To prevent short-term memory loss in autonomous agents, the harness **mandates** that agents write their reasoning to `docs/cycle_logs/[task_id]_log.md` **before** any code change.

The engine validates:
- The cycle log file exists
- It was modified within the last 120 seconds

Test execution is **rejected** if the cycle log is missing or stale.

## Core Principles

1.  **Repository as SOR**: All state (tasks, maps, decisions) must live in the repo (`docs/tasks/*.json`, `docs/map.md`).
2.  **Mechanical Invariant Enforcement**: Rules are enforced by a hardened CLI (`harness.sh`). **Note**: The `harness.sh` engine is NOT located in the user's project repository. It is stored in your global skills directory.
3.  **Shell-Safe Execution**: Commands are executed via `bash -c` (no `eval`). No `sudo` or privilege escalation.
4.  **Cross-Validation Integrity**: The system re-verifies the physical telemetry log against the registry hash before every sensitive operation (e.g., `commit`).
5.  **Agent-Native Execution**: The agent must resolve the absolute path of its skill directory (e.g., `/Users/.../skills/harness/scripts/harness.sh`) before executing. Do NOT copy `harness.sh` to the local project.
6.  **Context-Aware Governance (AGENTS.md)**:
    - **Rule 1 (Check First)**: Before starting any task, check if `AGENTS.md` exists in the project root.
    - **Rule 2 (Preservation)**: IF `AGENTS.md` exists, read and follow it. Do NOT modify it.
    - **Rule 3 (Creation)**: IF `AGENTS.md` does NOT exist, generate it using the Harness Protocol template.
    - **Rule 4 (Explicit Override)**: Only modify `AGENTS.md` if the user explicitly commands it.

## Workflow

0. **[GOVERNANCE]**: Check for `AGENTS.md` in root. If exists, read and follow. If not, generate.
1. **[PROPOSE]**: Define task in `docs/tasks/[task_id].json`.
2. **[REASON]**: Write reasoning to `docs/cycle_logs/[task_id]_log.md`.
3. **[ACT]**: Implement changes and tests.
4. **[VERIFY]**: Run `bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id [task_id] --cmd "[command]"`.
5. **[DOCUMENT]**: Run `bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_42010`.
6. **[CLOSE]**: Run `bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh commit --id [task_id] --msg "[message]"`.

## Usage Examples

```bash
# Full pipeline with interactive approval gates
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh run --id TASK-001 --level 3

# TDD Red phase verification
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --mode tdd-red --id TASK-001-RED --cmd "c8 node --test test.js"

# Standard verification (requires 80%+ coverage)
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id TASK-001 --cmd "c8 node --test test.js"

# Generate ISO documentation
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_42010
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_25010

# Commit with coverage validation
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh commit --id TASK-001 --msg "feat: add validation"

# Scaffold documentation structure in target project
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh docs-init

# Scaffold specific template only
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh docs-init --template SRS

# Generate prompt only (Level 2)
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh run --id TASK-001 --level 2
```

## Guardrails & Security

- **Tamper Resistance**: Any modification to `.harness/` by an AI agent results in an immediate **Integrity Violation**.
- **Context Optimization**: Keep `<failure_context>` under 100 tokens. Use `<log_ref path="..." lines="..."/>` for details.
- **Loop Protection**: Maximum 3 self-healing attempts before mandatory Human Hand-off.
- **Strict Verification (Coverage-Driven)**: Every task MUST be verified via `harness.sh test`.
  - **Coverage Threshold**: **Line Coverage MUST be >= 80%** (via LCOV).
  - **Hardened Verification**: The system blocks `grep`, `ls`, `cat`, `echo`, and `node -e` as test commands.
  - **Behavioral Evidence**: Agents must provide actual behavioral proof via test scripts with coverage tools.
- **Cycle Log Enforcement**: Test execution is blocked if `docs/cycle_logs/[task_id]_log.md` is missing or stale.
- **No Privilege Escalation**: `harness.sh` never uses `sudo` or any privilege escalation commands.

## ROI & Estimation (Business Metrics)

Every task tracks its own productivity metrics:
- **`tokens_used`**: Estimated API cost for this task.
- **`retry_count`**: Number of self-healing loops required.
- **`duration_seconds`**: Real-world time from `Ready` to `Approved`.
- **`assigned_sub_agent`**: Which sub-agent handled this task.
- **`sub_task_status`**: Delegation lifecycle state.

## Mandatory Artifacts

### 1. The Task Registry (`docs/tasks/`)
A directory-based registry where each task has its own JSON file.
- **Path**: `docs/tasks/[task_id].json`

### 2. Automated Semantic Map (`docs/map.md`)
An auto-generated index of all functions, classes, and domain boundaries.

### 3. Prompt Template (`assets/PROMPT.md`)
All tasks must use the `PROMPT.md` template for ACI prompt generation.

### 4. Cycle Logs (`docs/cycle_logs/`)
Mandatory reasoning logs that document agent decision-making before each code change.

## Documentation Templates

The harness provides a complete set of software engineering and agile document templates. Use `harness.sh docs-init` to scaffold these into a target project.

| Template | File | Purpose |
|---|---|---|
| **SRS** | `assets/templates/SRS_template.md` | Software Requirements Specification |
| **SDD** | `assets/templates/SDD_template.md` | Software Design Document |
| **SCS** | `assets/templates/SCS_template.md` | Software Configuration Specification |
| **Kanban** | `assets/templates/KANBAN_template.md` | Task tracking with WIP limits |
| **Scrum** | `assets/templates/SCRUM_template.md` | Sprint & daily progress tracking |
| **ADR** | `assets/templates/ADR_template.md` | Architecture Decision Record |
| **STD** | `assets/templates/STD_template.md` | Software Test Design (TDD-aligned) |
| **STR** | `assets/templates/STR_template.md` | Software Test Report (telemetry-integrated) |
| **API Spec** | `assets/templates/API_SPEC_template.md` | API & Interface Specification |
| **Troubleshooting** | `assets/templates/TROUBLESHOOTING_template.md` | Error resolution & incident log |
