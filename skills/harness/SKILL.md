---
name: harness
description: A high-reliability, telemetry-backed autonomous agent protocol. Implements "Harness-as-a-Protocol" with automated steering, hybrid reference context management, and developer-aware actor detection.
license: MIT
metadata:
  author: dragoncowkarma
  version: "1.0.0"
  architecture: "Harness-as-a-Protocol"
---

# `harness` Skill: The Autonomous Protocol

The `harness` skill transforms the repository into a self-regulating "hardware harness" for AI agents. It prioritizes the **Repository as the System of Record (SOR)** and enforces governance through **Mechanical Invariants** and **Automated Steering via Git Hooks**.

## TDD Workflow

To prevent "tautological testing" and hallucination, development must be split into two consecutive tasks:

1.  **RED Task (Adversarial QA)**:
    - **Goal**: Write failing tests based on requirements.
    - **Naming**: `[task_id]-RED.json`.
    - **Execution**: `harness test --mode tdd-red --id [id] --cmd "[cmd]"`.
    - **Constraint**: You are ONLY allowed to modify test files. Production files must remain untouched.
    - **Validation**: The engine rejects SyntaxErrors. You must produce a valid `AssertionError`.
2.  **GREEN Task (Implementation Engineer)**:
    - **Goal**: Write production code to satisfy the tests.
    - **Naming**: `[task_id]-GREEN.json`.
    - **Dependency**: Must list the RED task in `depends_on`.
    - **Execution**: Standard `harness test`.
    - **Validation**: Must achieve 80%+ Line Coverage.

## Core Principles

1.  **Repository as SOR**: All state (tasks, maps, decisions) must live in the repo (`docs/tasks/*.json`, `docs/map.md`).
2.  **Mechanical Invariant Enforcement**: Rules are enforced by a hardened CLI (`harness.py`). **Note**: The `harness.py` engine is NOT located in the user's project repository. It is stored in your global skills directory.
3.  **Shell-Safe Execution**: Commands are executed via `shlex` and `subprocess` (shell=False) to prevent command injection.
4.  **Cross-Validation Integrity**: The system re-verifies the physical telemetry log against the registry hash before every sensitive operation (e.g., `commit`). This prevents agents from manual JSON tampering.
5.  **Agent-Native Execution**: The agent must automatically resolve the actual absolute path of its own skill directory (e.g., `/Users/macbook/Desktop/skills/skills/harness/scripts/harness.py`) before executing any commands. Do NOT attempt to copy `harness.py` to the local project.
6.  **Context-Aware Governance (AGENTS.md)**:
    - **Rule 1 (Check First)**: Before starting any epic or task, the agent MUST check if `AGENTS.md` exists in the project root.
    - **Rule 2 (Preservation)**: IF `AGENTS.md` already exists, you MUST read it to understand the project's existing governance. You are STRICTLY FORBIDDEN from modifying or adding rules to it by default. Respect the existing rules.
    - **Rule 3 (Creation)**: IF `AGENTS.md` does NOT exist, you MUST generate it using the standard "Harness Protocol Governance" template.
    - **Rule 4 (Explicit Override)**: The ONLY exception to Rule 2 is if the human user explicitly commands you to "update", "modify", or "add rules to" `AGENTS.md` in their prompt.

2.  **[ACT]**: Agent implements the change and writes unit tests.
3.  **[VERIFY]**: Agent runs tests via `harness test --id [task_id] --cmd "[command]"`. The system re-verifies the physical telemetry log against the registry hash, calculates **Line Coverage** (must be >= 80%), and sets status to `Verified`. ALL tasks MUST go through this step. Bypassing this step or skipping straight to the next task is an Integrity Violation.
4.  **[DOCUMENT]**: Agent synchronizes architectural and quality documentation using ISO standard templates.
    - `harness document --standard ISO_42010`: Updates `docs/architecture.md`.
    - `harness document --standard ISO_25010`: Updates `docs/quality_metrics.md`.
5.  **[CLOSE]**: Agent submits final diff via `harness commit --id [task_id] --msg "[message]"`. System allows commit if status is Verified and coverage is validated.

## ROI & Estimation (Business Metrics)

Every task in the registry tracks its own productivity metrics:
- **`tokens_used`**: Estimated API cost for this task.
- **`retry_count`**: Number of self-healing loops required.
- **`duration_seconds`**: Real-world time from `Ready` to `Approved`.

These metrics allow PMs to calculate the **AI Velocity** and provide data-driven estimations for future milestones.

## Mandatory Artifacts

### 1. The Task Registry (`docs/tasks/`)
A directory-based registry where each task has its own JSON file. This prevents merge conflicts in multi-agent environments.
- **Path**: `docs/tasks/[task_id].json`

### 2. Automated Semantic Map (`docs/map.md`)
An auto-generated index of all functions, classes, and domain boundaries.
- **Maintenance**: Updated automatically by `harness --map` using AST parsing.

### 3. XML ACI Prompts (`docs/prompts/`)
All tasks must use the `PROMPT.xml` template, which enforces the **Hybrid Reference** pattern.

## Guardrails & Security

- **Tamper Resistance**: Any modification to `.harness/` by an AI agent results in an immediate **Integrity Violation** and task freeze.
- **Context Optimization**: Keep `<failure_context>` under 100 tokens. Always use `<log_ref path="..." lines="..."/>` for detailed debugging data.
- **Loop Protection**: Maximum 3 self-healing attempts before mandatory Human Hand-off.
- **Strict Verification (Coverage-Driven)**: Every single task MUST be verified via the `harness test` CLI. 
  - **Coverage Threshold**: **Line Coverage MUST be >= 80%** (via LCOV). Failing to provide a coverage report or falling below the threshold results in an immediate **Integrity Violation**.
  - **Hardened Verification**: The system physically blocks `grep`, `ls`, `cat`, `echo`, and `node -e` as root test commands.
  - **Behavioral Evidence**: Agents must provide actual behavioral proof via test scripts (e.g., Jest, Pytest, Node) with coverage tools (e.g., c8, nyc). Simple string matching or file existence checks are strictly forbidden.

[Workflow]
0. [GOVERNANCE]: Check for `AGENTS.md` in root. If exists, read and follow. If not, generate using Harness template.
1. [PROPOSE]: Define task in `docs/tasks/[task_id].json`.
2. [ACT]: Implement changes and tests.
3. [VERIFY]: Run `python3 [ABSOLUTE_SKILL_PATH]/scripts/harness.py test --id [task_id] --cmd "[command]"`.
4. [DOCUMENT]: Run `python3 [ABSOLUTE_SKILL_PATH]/scripts/harness.py document --standard ISO_42010`.
5. [CLOSE]: Run `python3 [ABSOLUTE_SKILL_PATH]/scripts/harness.py commit --id [task_id] --msg "[message]"`.

[Usage Examples]
# Manually trigger verification (e.g., using c8 for coverage)
python3 [ABSOLUTE_SKILL_PATH]/scripts/harness.py test --id [task_id] --cmd "c8 node --test [test_file]"

# Commit with coverage validation
python3 [ABSOLUTE_SKILL_PATH]/scripts/harness.py commit --id [task_id] --msg "Detailed commit message"
