# [TARGET: {target_file}] [TASK: {task_id}]

## Task Metadata

| Field | Value |
|---|---|
| **Task ID** | `{task_id}` |
| **Agent Role** | `{agent_role}` |
| **Priority** | `{priority}` |

### Sub-Agent Dispatch Rules

| Role | Phase | Constraint |
|---|---|---|
| **QA** | RED | Write failing tests that define behavioral expectations. STRICTLY FORBIDDEN from modifying production code files. |
| **Dev** | GREEN | Implement production code to satisfy the RED tests. May modify production and test files. |
| **Doc** | DOCUMENT | Update `docs/` directory files. STRICTLY FORBIDDEN from modifying `src/` and `tests/` directories. |

---

## Context Links

Use the Semantic Map (`docs/map.md`) to locate symbols:

- **Map**: `docs/map.md` — Required symbols: `{required_symbols}`
- **Delta**: `docs/delta/{dependency_id}.json`

> **Hybrid Reference Rule**: Do NOT paste large logs inline. Use path references instead.

{log_references}

---

## Reasoning Protocol (Tree of Thought)

> **MANDATORY**: You MUST write to `docs/cycle_logs/{task_id}_log.md` BEFORE writing any code.

### Required Cycle Log Format

```markdown
## Cycle [N] — [timestamp]

### Intent
[Why am I doing this? What is the goal?]

### Analysis
[What did I observe? What context informs this decision?]

### Plan
[What specific changes will I make?]

### Failure Modes
[Predict at least 2 worst-case scenarios.]
```

> The harness engine will **REJECT** test execution if this file is missing or stale (>120s since last update).

### Phase-Specific Reasoning

1. **RED_PHASE**: Describe the specific assertion that will fail and why. DO NOT IMPLEMENT PRODUCTION LOGIC.
2. **GREEN_PHASE**: Describe the implementation logic to satisfy the RED tests.

**Rationale**: Cycle logs prevent short-term memory volatility in autonomous agents and ensure every decision is auditable.

---

## Work Scope

**Target File**: `{target_file}`

### Constraints

- Surgical edits only. No refactoring of adjacent code.
- **RED PHASE**: If `task_id` ends in `-RED`, you are STRICTLY FORBIDDEN from modifying production files. You may only edit files in `tests/` or equivalent.
- Do NOT touch `.harness/` or `.git/` directories.
- Do NOT copy `harness.sh` to the local project directory. Always execute it from the skill workspace using its absolute path.
- **DOCUMENT PHASE**: During `[DOCUMENT]`, you are STRICTLY FORBIDDEN from modifying production or test code. You may ONLY update files in `docs/`.

---

## Mechanical Definition of Done

You MUST use the harness CLI to run tests and lock the telemetry hash.

### TDD Enforcement

| Task Type | Command |
|---|---|
| `*-RED` tasks | `bash [PATH]/harness.sh test --mode tdd-red --id {task_id} --cmd "{cmd}"` |
| `*-GREEN` tasks | `bash [PATH]/harness.sh test --id {task_id} --cmd "{cmd}"` |

> **CRITICAL**: Standard mode requires **MANDATORY Line Coverage >= 80%**.
> You MUST use a coverage tool (e.g., `c8`, `nyc`) with your test runner.
> Example: `c8 node --test timer.test.js`

### Integrity Violations

The system **PHYSICALLY BLOCKS** the following commands to prevent coverage bypass:
`grep`, `ls`, `cat`, `echo`, `node -e`

Attempting to use these will result in an **immediate task freeze**.

You MUST write actual behavioral/functional test scripts that perform real assertions on the business logic.

### Governance Constraint

Never overwrite or modify an existing `AGENTS.md` unless the user's prompt contains an explicit request to do so. Default behavior is **Read-Only** for existing `AGENTS.md`.

### Verification Command

```bash
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id {task_id} --cmd "{validation_command}"
```

### Telemetry Check

| Metric | Expected |
|---|---|
| Status | `Verified` |
| Coverage | Min 80% Line Coverage (LCOV) |
| Hash Integrity | Locked by System with Salt |

---

## Documentation Hook

Once Verified, you MUST synchronize the project's ISO documentation:

1. **Architecture**: `bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_42010`
2. **Quality**: `bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_25010`

**Output Files**:
- `docs/architecture.md`
- `docs/quality_metrics.md`

---

## Failure Handling

- **Retry Limit**: 3 attempts maximum
- **On Failure**: Update `docs/tasks/{task_id}.json` with status `[Failed]` and analyze `coverage/lcov.info` to find untested paths.

---

## Workflow Reference

> For the complete 6-step workflow (GOVERNANCE → PROPOSE → REASON → ACT → VERIFY → DOCUMENT → CLOSE), see [SKILL.md](../SKILL.md#workflow).

---

## Thought Process

<!-- Write your System 2 reasoning here -->

## Code Change

<!-- Implementation goes here -->
