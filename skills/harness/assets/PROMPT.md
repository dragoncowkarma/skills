# [TARGET: {target_file}] [TASK: {task_id}]

## Task Metadata

| Field | Value |
|---|---|
| **Task ID** | `{task_id}` |
| **Agent Role** | `{agent_role}` |
| **Priority** | `{priority}` |

---

## Context Links

Use the Semantic Map (`docs/map.md`) to locate symbols:

- **Map**: `docs/map.md` — Required symbols: `{required_symbols}`
- **Delta**: `docs/delta/{dependency_id}.json`

{log_references}

---

## Work Scope

**Target File**: `{target_file}`

### Phase Constraints

- **RED Phase**: If `task_id` ends in `-RED`, you are assigned as `QA` and are STRICTLY FORBIDDEN from modifying production files. You may only edit files in `tests/` or equivalent.
- **GREEN Phase**: If `task_id` ends in `-GREEN`, you are assigned as `DEV` and may modify production and test files to satisfy the tests.
- **DOCUMENT Phase**: If you are assigned as `DOC`, you are STRICTLY FORBIDDEN from modifying production or test code. You may ONLY update files in `docs/` or equivalent.

---

## Dynamic State

### Failure Context

{failure_context}

---

## Thought Process

<!-- Write your System 2 reasoning here -->

## Code Change

<!-- Implementation goes here -->
