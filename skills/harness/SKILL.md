---
name: harness
description: A high-reliability, telemetry-backed autonomous agent protocol with sub-agent delegation, autonomy level control, and mandatory thought-process logging. Implements "Harness-as-a-Protocol" with automated steering and developer-aware actor detection.
license: MIT
metadata:
  author: dragoncowkarma
  version: "3.0.0"
  architecture: "Harness-as-a-Protocol"
---

# `harness` Skill: The Autonomous Protocol

The `harness` skill transforms the repository into a self-regulating "hardware harness" for AI agents. It prioritizes the **Repository as the System of Record (SOR)** and enforces governance through **Mechanical Invariants** and **Automated Steering via Git Hooks**.

## Environment Setup & Permissions

Before running the harness script, execution permissions must be granted to the file to prevent `Permission denied` errors.

> [!IMPORTANT]
> **Execution Permission Required**
> Prior to executing the script or configuring the environment, you MUST grant execution permission to the shell script using `chmod +x`:
> ```bash
> chmod +x [ABSOLUTE_SKILL_PATH]/scripts/harness.sh
> ```

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
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh run --id TASK-001 --level 4
```

## CI/Headless Mode

For CI/CD pipeline integration, use `--ci` to disable all interactive prompts:

```bash
# Run pipeline in CI mode (no user prompts)
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh run --id TASK-001 --level 3 --ci

# CI approval with token
HARNESS_CI_TOKEN="your-token" [ABSOLUTE_SKILL_PATH]/scripts/harness.sh approve --id TASK-001 --ci
```

In CI mode:
- Level 3 approval gates are auto-bypassed
- Approval requires `HARNESS_CI_TOKEN` environment variable
- ANSI color codes are stripped from output (plain text)

## Adapter System (Multi-Environment Support)

The harness uses a plugin/adapter pattern for coverage and mutation testing tools:

| Adapter | Coverage Tool | Mutation Tool | Activate |
|---------|--------------|---------------|----------|
| **node** (default) | c8, nyc (LCOV) | Stryker | `--adapter node` or env `HARNESS_ADAPTER=node` |
| **kmp** | Kover (LCOV) | PIT (pitest) | `--adapter kmp` |
| **unity** | dotCover, coverlet | Stryker.NET | `--adapter unity` |

Adapters are loaded from `scripts/adapters/{name}.sh`. Custom adapters can be added by implementing the adapter interface:
- `adapter_parse_coverage(lcov_path)` — Parse coverage report, return percentage
- `adapter_run_mutation(task_id, threshold, log_path)` — Run mutation testing
- `adapter_allowed_prefixes()` — Return space-separated list of allowed command prefixes

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

## Mutation Testing (Quality Coverage)

Beyond quantitative coverage (80% line coverage), use mutation testing for qualitative validation:

```bash
# Standard test + mutation testing
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id TASK-001 --cmd "c8 node --test test.js" --mutation

# Custom mutation threshold (default: 60%)
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id TASK-001 --cmd "c8 node --test test.js" --mutation --mutation-threshold 70
```

Mutation score is recorded in `metrics.mutation_score` in the task JSON.

## Reasoning Protocol (Cycle Logs)

To prevent short-term memory loss in autonomous agents, the harness **mandates** that agents write their reasoning to `docs/cycle_logs/[task_id]_log.md` **before** any code change.

The engine validates:
- The cycle log file exists
- It was modified within the last 120 seconds

Test execution is **rejected** if the cycle log is missing or stale.

### Self-Reflection on Retry

When retrying a failed task, agents MUST inject a `<failure_context>` tag (max 100 chars) into their reasoning, documenting:
- Previous failure root cause
- What was attempted
- What will change this time

After 3 failed attempts, emit `<human_handoff reason="..."/>` and STOP.

## Core Principles

1.  **Repository as SOR**: All state (tasks, maps, decisions) must live in the repo (`docs/tasks/*.json`, `docs/map.md`).
2.  **Mechanical Invariant Enforcement**: Rules are enforced by a hardened CLI (`harness.sh`). **Note**: The `harness.sh` engine is NOT located in the user's project repository. It is stored in your global skills directory.
3.  **Shell-Safe Execution**: Commands are validated against an **allowlist** (no shell metacharacter chaining). No `sudo` or privilege escalation.
4.  **Cross-Validation Integrity**: The system re-verifies the physical telemetry log against the registry hash before every sensitive operation (e.g., `commit`).
5.  **Agent-Native Execution**: The agent must resolve the absolute path of its skill directory (e.g., `/Users/.../skills/harness/scripts/harness.sh`) before executing. Do NOT copy `harness.sh` to the local project.
6.  **Context-Aware Governance (AGENTS.md)**:
    - **Rule 1 (Check First)**: Before starting any task, check if `AGENTS.md` exists in the project root.
    - **Rule 2 (Preservation)**: IF `AGENTS.md` exists, read and follow it. Do NOT modify it.
    - **Rule 3 (Creation)**: IF `AGENTS.md` does NOT exist, generate it using the Harness Protocol template.
    - **Rule 4 (Explicit Override)**: Only modify `AGENTS.md` if the user explicitly commands it.
7.  **Log Masking**: All telemetry and cycle logs are automatically scrubbed of PII, secrets, API keys, JWT tokens, and IP addresses before storage.

## Workflow

0. **[GOVERNANCE]**: Check for `AGENTS.md` in root. If exists, read and follow. If not, generate.
1. **[PROPOSE]**: Define task in `docs/tasks/[task_id].json`.
2. **[REASON]**: Write reasoning to `docs/cycle_logs/[task_id]_log.md`.
3. **[ACT]**: Implement changes and tests.
4. **[VERIFY]**: Run `[ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id [task_id] --cmd "[command]"`.
5. **[DOCUMENT]**: Run `[ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_42010`.
   - Use **fragment-based updates** — do not rewrite monolithic documents. Read `docs/index.md` first, route to the correct fragmented file (e.g., `docs/requirements/auth.md`), and apply surgical updates.
   - For KANBAN: Run `[ABSOLUTE_SKILL_PATH]/scripts/harness.sh kanban-render` (SSOT, do not edit directly).
   - For Human Review: Run `[ABSOLUTE_SKILL_PATH]/scripts/harness.sh document-build` to stitch fragments together.
6. **[CLOSE]**: Run `[ABSOLUTE_SKILL_PATH]/scripts/harness.sh commit --id [task_id] --msg "[message]"`.

## Usage Examples

```bash
# Full pipeline with interactive approval gates
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh run --id TASK-001 --level 3

# Full pipeline in CI mode (no prompts)
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh run --id TASK-001 --level 3 --ci

# TDD Red phase verification
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --mode tdd-red --id TASK-001-RED --cmd "c8 node --test test.js"

# Standard verification with mutation testing
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id TASK-001 --cmd "c8 node --test test.js" --mutation

# Kotlin/KMP project
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id TASK-001 --cmd "./gradlew test" --adapter kmp

# Generate ISO documentation
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_42010
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_25010

# Commit with coverage validation
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh commit --id TASK-001 --msg "feat: add validation"

# Scaffold all documentation templates
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh docs-init

# Scaffold essential templates only (SRS, SDD, KANBAN, WBS)
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh docs-init --lite

# Scaffold specific template
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh docs-init --template WBS

# Render Kanban board from task data (SSOT)
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh kanban-render

# Archive old completed tasks (default: 7 days)
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh archive
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh archive --archive-days 14

# Generate prompt (Level 2)
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh run --id TASK-001 --level 2
```

## Guardrails & Security

- **Tamper Resistance**: Any modification to `.harness/` by an AI agent results in an immediate **Integrity Violation**.
- **Context Optimization**: Keep `<failure_context>` under 100 tokens. Use `<log_ref path="..." lines="..."/>` for details.
- **Loop Protection**: Maximum 3 self-healing attempts before mandatory Human Hand-off.
- **Strict Verification (Coverage-Driven)**: Every task MUST be verified via `harness.sh test`.
  - **Coverage Threshold**: **Line Coverage MUST be >= 80%** (via LCOV).
  - **Mutation Threshold**: **Mutation Score MUST be >= 60%** (when `--mutation` enabled).
  - **Allowlist Verification**: Only approved test tool commands are accepted. Shell metacharacters (`;`, `&&`, `||`, `|`, `$(`, `` ` ``) are blocked.
  - **Behavioral Evidence**: Agents must provide actual behavioral proof via test scripts with coverage tools.
- **Cycle Log Enforcement**: Test execution is blocked if `docs/cycle_logs/[task_id]_log.md` is missing or stale.
- **No Privilege Escalation**: `harness.sh` never uses `sudo` or any privilege escalation commands.
- **Log Masking (PII Redaction)**: Telemetry logs and cycle logs are automatically scrubbed of:
  - Email addresses → `[REDACTED:email]`
  - API keys / tokens / secrets → `[REDACTED]`
  - JWT tokens → `[REDACTED:jwt]`
  - IP addresses → `[REDACTED:ip]`
- **Safe DB Policy**: Agent-generated migrations MUST NOT contain `DROP TABLE`, `TRUNCATE`, or unguarded `DELETE`. Memory DB sandbox required for tests.

## ROI & Estimation (Business Metrics)

Every task tracks its own productivity metrics:
- **`tokens_used`**: Estimated API cost for this task.
- **`retry_count`**: Number of self-healing loops required.
- **`duration_seconds`**: Real-world time from `Ready` to `Approved`.
- **`assigned_sub_agent`**: Which sub-agent handled this task.
- **`sub_task_status`**: Delegation lifecycle state.
- **`coverage`**: Line coverage percentage.
- **`mutation_score`**: Mutation testing score (when enabled).

The ISO 25010 quality report includes a **Cost & Token Dashboard** aggregating total tokens used and estimated USD cost per feature.

## Log Rotation & Archival

To prevent file accumulation, the harness includes automatic archival:

```bash
# Archive tasks completed > 7 days ago
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh archive

# Custom retention period
[ABSOLUTE_SKILL_PATH]/scripts/harness.sh archive --archive-days 14
```

- **Scope**: Approved tasks in `docs/tasks/` and corresponding telemetry in `.harness/telemetry/`
- **Destination**: `.archive/tasks/` and `.archive/telemetry/` (gzip compressed)
- **Default Retention**: 7 days after approval

## Mandatory Artifacts

### 1. The Task Registry (`docs/tasks/`)
A directory-based registry where each task has its own JSON file.
- **Path**: `docs/tasks/[task_id].json`

### 2. Automated Semantic Map (`docs/map.md`)
An auto-generated index of all functions, classes, and domain boundaries.
- **AST Integration**: Use `tree-sitter`, `ctags`, or `LSIF` for accurate symbol indexing.

### 3. Prompt Template (`assets/PROMPT.md`)
All tasks must use the `PROMPT.md` template for ACI prompt generation.

### 4. Cycle Logs (`docs/cycle_logs/`)
Mandatory reasoning logs that document agent decision-making before each code change.

## Documentation Templates & Fragmented Architecture

The harness utilizes a **Fragment-Based Documentation Architecture** to optimize AI token context and prevent monolithic file management. 

### Directory Structure
```
docs/
├── index.md                  # Master Index (Routing file for AI agents)
├── requirements/             # Fragmented SRS/Functional specs
├── architecture/             # Fragmented SDD/ISO_42010 components
├── management/               # Kanban, Scrum, ADRs, Troubleshooting
└── tasks/                    # Task JSONs
```

**AI Documentation Rule:** Agents must NEVER rewrite entire documents. They should first read `docs/index.md` to map the structure, then locate and surgically modify only the specific fragment file needed. To compile for human reading, use `harness.sh document-build`.

### Available Templates
The harness provides a complete set of software engineering and agile document templates. Use `harness.sh docs-init` to scaffold the fragmented directory structure and these templates into a target project, or `harness.sh docs-init --lite` for essentials only.

| Template | File | Purpose |
|---|---|---|
| **SRS** | `assets/templates/srs_template.md` | Software Requirements Specification |
| **SDD** | `assets/templates/sdd_template.md` | Software Design Document |
| **SCS** | `assets/templates/scs_template.md` | Software Configuration Specification |
| **Kanban** | `assets/templates/kanban_template.md` | Task tracking — SSOT view (auto-rendered) |
| **WBS** | `assets/templates/wbs_template.md` | Work Breakdown Structure (Phase/Task/Sub-task) |
| **Scrum** | `assets/templates/scrum_template.md` | Sprint & daily progress tracking |
| **ADR** | `assets/templates/adr_template.md` | Architecture Decision Record |
| **STD** | `assets/templates/std_template.md` | Software Test Design (TDD-aligned) |
| **STR** | `assets/templates/str_template.md` | Software Test Report (telemetry-integrated) |
| **API Spec** | `assets/templates/api_spec_template.md` | API Specification (OpenAPI 3.0 YAML) |
| **Troubleshooting** | `assets/templates/troubleshooting_template.md` | Error resolution & incident log |
| **ISO 25010** | `assets/templates/iso_25010_template.md` | Quality Metrics Dashboard |
| **ISO 42010** | `assets/templates/iso_42010_template.md` | Architecture Specification |
| **Map** | `assets/templates/map_template.md` | Semantic Map |
| **Tasks** | `assets/templates/tasks_template.json` | Task JSON Definition |
