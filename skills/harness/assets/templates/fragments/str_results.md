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
