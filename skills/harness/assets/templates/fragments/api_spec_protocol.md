## 2. Harness Sub-Agent Communication Protocol

### 2.1 Task Dispatch Contract

The harness dispatches tasks to sub-agents via task JSON files (`docs/tasks/{task_id}.json`):

| Field | Type | Purpose |
|---|---|---|
| `id` | string | Unique task identifier |
| `assigned_sub_agent` | `"QA" / "DEV" / "DOC" / null` | Target sub-agent role |
| `sub_task_status` | `"Pending" / "InProgress" / "Completed" / "Failed"` | Delegation lifecycle |
| `mechanical_dod.command` | string | Verification command to execute |
| `mechanical_dod.expected_exit_code` | int | Expected result |
| `depends_on` | string[] | Task IDs that must complete first |

### 2.2 Sub-Agent Permissions Matrix

| Sub-Agent | Can Modify `src/` | Can Modify `tests/` | Can Modify `docs/` | Can Modify `.harness/` |
|---|---|---|---|---|
| **QA** (RED) | ❌ | ✅ | ❌ | ❌ |
| **DEV** (GREEN) | ✅ | ✅ | ❌ | ❌ |
| **DOC** (DOCUMENT) | ❌ | ❌ | ✅ | ❌ |

### 2.3 Telemetry Communication

| Event | Producer | Consumer | Data |
|---|---|---|---|
| Test Complete | `harness.sh test` | `.harness/telemetry/{task_id}.log` | Exit code, coverage, duration |
| Status Update | `harness.sh test` | `docs/tasks/{task_id}.json` | Status, hash, metrics |
| Doc Sync | `harness.sh document` | `docs/architecture.md`, `docs/quality_metrics.md` | Generated docs |
