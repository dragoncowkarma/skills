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
