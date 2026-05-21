## 1. Test Execution Overview

### 1.1 Scope

| Aspect | Detail |
|---|---|
| **Test Suite Executed** | {Smoke / Core / Full} |
| **Build/Commit** | `{commit_sha}` |
| **Execution Date** | {DATE} |
| **Executor** | {Agent (antigravity/jules) / Developer Name} |
| **Environment** | {Development / CI / Staging} |
| **Harness Autonomy Level** | {1-4} |

### 1.2 Verdict

| Metric | Value | Threshold | Verdict |
|---|---|---|---|
| **Total Test Cases** | {N} | — | — |
| **Passed** | {N} ({N}%) | — | — |
| **Failed** | {N} ({N}%) | 0 for release | {PASS / FAIL} |
| **Skipped** | {N} ({N}%) | < 5% | {PASS / FAIL} |
| **Line Coverage** | {N}% | ≥ 80% (harness enforced) | {PASS / FAIL} |
| **Branch Coverage** | {N}% | ≥ {N}% (recommended) | {PASS / FAIL} |
| **Overall Status** | — | — | **{PASS / FAIL}** |

---

## 2. Execution Summary (Harness Telemetry)

> Auto-populated from `docs/tasks/*.json` and `.harness/telemetry/`

### 2.1 Task-Level Results

| Task ID | Mode | Status | Coverage | Duration | Retries | Telemetry Hash |
|---|---|---|---|---|---|---|
| {TASK-XXX}-RED | tdd-red | {Verified} | N/A | {5s} | {0} | `{hash}` |
| {TASK-XXX}-GREEN | standard | {Verified} | {87%} | {12s} | {1} | `{hash}` |
| {TASK-YYY}-RED | tdd-red | {Verified} | N/A | {3s} | {0} | `{hash}` |
| {TASK-YYY}-GREEN | standard | {Failed} | {65%} | {8s} | {3} | `{hash}` |

### 2.2 Aggregate Metrics

| Metric | Value |
|---|---|
| **Total Tasks Executed** | {N} |
| **Verified Tasks** | {N} ({N}%) |
| **Failed Tasks** | {N} ({N}%) |
| **Average Line Coverage** | {N}% |
| **Average Duration** | {N}s |
| **Total Retries** | {N} |
| **Retry Rate** | {N}% |
| **Integrity Violations** | {N} |
