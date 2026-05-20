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

### Dynamic Analysis & AST Indexing

When generating or updating `docs/map.md`, you MUST use AST-based indexing tools for accuracy:

1. **Preferred Tools** (in order of preference):
   - `tree-sitter` — Language-agnostic AST parsing. Use `tree-sitter parse <file>` to extract symbols.
   - `ctags` / `universal-ctags` — Generate symbol tables. Run `ctags -R --output-format=json` for machine-readable output.
   - `LSIF` (Language Server Index Format) — For IDE-grade precision. Use project-specific LSIF generators (e.g., `lsif-tsc` for TypeScript).

2. **Synchronization Rule**: After any code change that adds, removes, or renames a public symbol (function, class, interface, type, constant), you MUST regenerate `docs/map.md` using the AST tool before proceeding to the DOCUMENT phase.

3. **Fallback**: If no AST tool is available, manually inspect changed files and update `map.md` with accurate symbol locations. Mark the entry with `[manual]` tag.

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

### Log Masking (Mandatory PII/Secrets Redaction)

Before writing ANY log data to `cycle_logs`, `telemetry`, or any output file, you MUST apply the following redaction pipeline:

| Pattern | Replacement | Example |
|---|---|---|
| Email addresses | `[REDACTED:email]` | `user@example.com` → `[REDACTED:email]` |
| API keys / tokens / secrets | `[REDACTED:api_key]` | `api_key=sk-abc123` → `api_key=[REDACTED]` |
| JWT tokens (`eyJ...`) | `[REDACTED:jwt]` | `eyJhbGciO...` → `[REDACTED:jwt]` |
| IP addresses | `[REDACTED:ip]` | `192.168.1.1` → `[REDACTED:ip]` |
| Passwords in config | `[REDACTED:password]` | `password=hunter2` → `password=[REDACTED]` |

> **Rule**: The harness engine (`harness.sh`) applies automatic masking to telemetry logs. You MUST also apply masking in cycle logs and any manually written output.

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

### Mutation Testing (Quality Coverage)

When `--mutation` is enabled, the harness additionally validates **qualitative** test coverage:

| Metric | Threshold | Tool |
|---|---|---|
| Mutation Score | >= 60% | Adapter-specific (default: Stryker) |

```bash
bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh test --id {task_id} --cmd "{cmd}" --mutation
```

### Integrity Violations

The system uses an **allowlist** approach — only approved test tool commands are permitted. Attempting to use shell commands like `grep`, `ls`, `cat`, `echo`, `node -e`, or chaining with `;`, `&&`, `||`, `|` will result in an **immediate task freeze**.

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
| Mutation Score | Min 60% (when `--mutation` enabled) |
| Hash Integrity | Locked by System with Salt |

---

## Documentation Hook

Once Verified, you MUST synchronize the project's ISO documentation:

1. **Architecture**: `bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_42010`
2. **Quality**: `bash [ABSOLUTE_SKILL_PATH]/scripts/harness.sh document --standard ISO_25010`

**Output Files**:
- `docs/architecture.md`
- `docs/quality_metrics.md`

### Fragment-Based Update Strategy

> **IMPORTANT**: Do NOT regenerate entire documents when only a subset has changed.

When updating documentation:

1. **Detect Changes**: Compare the current task's scope against existing document sections.
2. **Surgical Update**: Modify only the sections/fragments affected by this task:
   - If a new component was added → append to Components section only.
   - If metrics changed → update the Metrics table rows only.
   - If a dependency was added → update Dependency section only.
3. **Preserve**: All sections not affected by this task MUST remain untouched.
4. **SSOT Rendering**: For `KANBAN.md`, do NOT edit directly. Run `harness.sh kanban-render` to regenerate from `docs/tasks/*.json`.

**Rationale**: Fragment-based updates reduce token cost, preserve manual annotations, and prevent merge conflicts in multi-agent scenarios.

---

## Failure Handling

- **Retry Limit**: 3 attempts maximum
- **On Failure**: Update `docs/tasks/{task_id}.json` with status `[Failed]` and analyze `coverage/lcov.info` to find untested paths.

### Self-Reflection Protocol (Mandatory on Retry)

When retrying a failed task, you MUST inject a compressed failure context into your reasoning:

```xml
<failure_context attempt="{N}" max_chars="100">
Attempt {N-1}: {compressed reason for failure and what was tried}
</failure_context>
```

**Rules**:
- The `<failure_context>` content MUST be 100 characters or fewer.
- Each retry appends to the accumulated context (most recent first).
- Focus on ROOT CAUSE, not symptoms.
- After 3 failed attempts, emit `<human_handoff reason="..."/>` and STOP.

**Example**:
```xml
<failure_context attempt="2" max_chars="100">
Attempt 1: LCOV missing — c8 not in devDeps. Tried: npm i -D c8. Fix: add c8 to test script.
</failure_context>
```

{failure_context}

---

## Workflow Reference

> For the complete 7-step workflow (GOVERNANCE → PROPOSE → REASON → ACT → VERIFY → DOCUMENT → CLOSE), see [SKILL.md](../SKILL.md#workflow).

---

## Thought Process

<!-- Write your System 2 reasoning here -->

## Code Change

<!-- Implementation goes here -->
