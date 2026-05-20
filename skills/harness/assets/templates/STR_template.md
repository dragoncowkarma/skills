# Software Test Report (STR)

> **Document ID**: STR-{PROJECT_ID}-001
> **Version**: 0.1.0
> **Last Updated**: {DATE}
> **Author**: {AUTHOR} / Harness Auto-Documentation
> **Sprint/Release**: {Sprint N / v1.0.0}
> **STD Reference**: [STD-{PROJECT_ID}-001](../testing/STD.md)

---

## Quick Start

1. This document is partially auto-populated by `harness.sh test` results
2. Section 2 (Execution Summary) updates automatically from telemetry
3. Section 3 (Detailed Results) requires manual curation for failed tests
4. Review after each sprint or release milestone

---

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

### 1.2 Overall Verdict

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

---

## 3. Detailed Test Results

### 3.1 Passed Tests

| TC ID | Test Name | Module | Duration | Notes |
|---|---|---|---|---|
| TC-{MODULE}-001 | {test_name} | {module} | {50ms} | — |
| TC-{MODULE}-002 | {test_name} | {module} | {120ms} | — |

### 3.2 Failed Tests

| TC ID | Test Name | Module | Failure Type | Root Cause | Resolution | Status |
|---|---|---|---|---|---|---|
| TC-{MODULE}-003 | {test_name} | {module} | {AssertionError / Timeout / Exception} | {Brief root cause} | {Fix applied / Deferred / Known issue} | {Fixed / Open} |

### 3.3 Skipped Tests

| TC ID | Test Name | Reason for Skip | Planned Re-enable Date |
|---|---|---|---|
| TC-{MODULE}-005 | {test_name} | {External dependency unavailable} | {DATE} |

---

## 4. Coverage Analysis

### 4.1 Coverage by Module

| Module | Lines | Lines Covered | Line Coverage | Branches | Branch Coverage |
|---|---|---|---|---|---|
| `{src/core/}` | {200} | {180} | {90%} | {50} | {80%} |
| `{src/utils/}` | {100} | {75} | {75%} | {20} | {70%} |
| **Total** | **{300}** | **{255}** | **{85%}** | **{70}** | **{77%}** |

### 4.2 Uncovered Code Analysis

| File | Uncovered Lines | Reason | Action |
|---|---|---|---|
| `{src/module/file.js}` | {L45-52} | {Error handling for rare edge case} | {Add test in next sprint} |
| `{src/module/file.js}` | {L100-105} | {Dead code} | {Remove in cleanup task} |

### 4.3 Coverage Trend

| Sprint/Date | Line Coverage | Branch Coverage | Delta |
|---|---|---|---|
| Sprint {N-2} | {78%} | {70%} | — |
| Sprint {N-1} | {82%} | {74%} | +4% / +4% |
| Sprint {N} | {85%} | {77%} | +3% / +3% |

---

## 5. Defect Summary

### 5.1 Defects Found

| Defect ID | Severity | Component | Description | Found By | Status | Linked TC |
|---|---|---|---|---|---|---|
| DEF-001 | {P0/P1/P2/P3} | {Module} | {Brief description} | {TC-XXX-NNN / Manual} | {Open/Fixed/Deferred} | TC-{MODULE}-{NNN} |

### 5.2 Defect Density

| Module | Lines of Code | Defects Found | Density (defects/KLOC) |
|---|---|---|---|
| `{module}` | {1000} | {2} | {2.0} |

### 5.3 Defect Aging

| Age Bucket | Count | Oldest |
|---|---|---|
| < 1 day | {N} | — |
| 1-7 days | {N} | DEF-{NNN} |
| > 7 days | {N} | DEF-{NNN} |

---

## 6. CI/CD Integration

### 6.1 Pipeline Execution Log

| Pipeline Run | Trigger | Branch | Duration | Result | Artifact |
|---|---|---|---|---|---|
| #{N} | {Push / PR / Schedule} | {main / feature/xxx} | {3m 45s} | {Pass / Fail} | {coverage/lcov.info} |

### 6.2 Harness Integration Points

| Hook | Trigger | Action | Status |
|---|---|---|---|
| Post-test | `harness.sh test` completes | Auto-append results to this STR | {Active / Configured / Planned} |
| Post-commit | `harness.sh commit` succeeds | Update task status in Kanban | {Active / Configured / Planned} |
| Pre-release | Manual trigger | Generate full STR summary | {Active / Configured / Planned} |

---

## 7. Risk Assessment

| Risk Area | Current Status | Risk Level | Mitigation |
|---|---|---|---|
| Coverage below threshold | {85% — above threshold} | Low | Maintain current testing discipline |
| Flaky tests | {0 identified} | Low | Monitor CI failure patterns |
| Untested requirements | {1 uncovered — REQ-XXX-003} | Medium | Schedule in next sprint |
| Performance regression | {Not yet tested} | High | Add performance test suite |

---

## 8. Recommendations & Next Steps

| # | Recommendation | Priority | Owner | Target Date |
|---|---|---|---|---|
| 1 | {Cover remaining uncovered lines in src/utils/} | High | {Agent/Dev} | {DATE} |
| 2 | {Add integration tests for new API endpoints} | Medium | {Agent/Dev} | {DATE} |
| 3 | {Implement mutation testing for core module} | Low | {Agent/Dev} | {DATE} |

---

## 9. Sign-off

| Role | Name | Verdict | Date |
|---|---|---|---|
| QA Lead | {Name} | {Approved / Rejected} | {DATE} |
| Dev Lead | {Name} | {Acknowledged} | {DATE} |
| Product Owner | {Name} | {Approved for release / Not approved} | {DATE} |

---

## Related Documents

| Document | Path | Relationship |
|---|---|---|
| Software Test Design | `docs/testing/STD.md` | Test cases executed in this report |
| Software Requirements Specification | `docs/specs/SRS.md` | Requirements under test |
| Quality Metrics (ISO 25010) | `docs/quality_metrics.md` | Harness auto-generated quality report |
| Troubleshooting Log | `docs/troubleshooting/TROUBLESHOOTING.md` | Failure investigation details |
