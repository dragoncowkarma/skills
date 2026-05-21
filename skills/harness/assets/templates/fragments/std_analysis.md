## 4. Boundary & Equivalence Analysis

### 4.1 Equivalence Classes

| Input | Valid Classes | Invalid Classes |
|---|---|---|
| `{parameter_name}` | {Class 1: 1-100}, {Class 2: "a"-"z"} | {Class 3: negative numbers}, {Class 4: empty string} |

### 4.2 Boundary Values

| Parameter | Min | Min+1 | Nominal | Max-1 | Max | Below Min | Above Max |
|---|---|---|---|---|---|---|---|
| `{param}` | {0} | {1} | {50} | {99} | {100} | {-1} | {101} |

### 4.3 Boundary Test Cases

| TC ID | Parameter | Value | Expected |
|---|---|---|---|
| TC-BND-001 | `{param}` | {0 (min)} | {Accept / Reject} |
| TC-BND-002 | `{param}` | {-1 (below min)} | {Reject with error} |
| TC-BND-003 | `{param}` | {100 (max)} | {Accept} |
| TC-BND-004 | `{param}` | {101 (above max)} | {Reject with error} |

---

## 5. Regression Suite

### 5.1 Regression Suite Definition

| Suite | Trigger | Test Cases Included | Max Duration |
|---|---|---|---|
| **Smoke** | Every commit | {TC-CORE-001, TC-CORE-002, ...} | 30s |
| **Core** | Every PR | {All unit + critical integration tests} | 5 min |
| **Full** | Pre-release / Nightly | {All test cases in this document} | 30 min |

### 5.2 Regression History

| Date | Suite | Pass | Fail | Skip | New Failures | Root Cause |
|---|---|---|---|---|---|---|
| {DATE} | {Core} | {45} | {2} | {1} | {TC-XXX-002} | {Dependency update broke mock} |

---

## 6. Mutation Testing

### 6.1 Mutation Testing Strategy

| Aspect | Configuration |
|---|---|
| **Tool** | {Stryker / mutmut / go-mutesting} |
| **Target Modules** | {List critical modules for mutation testing} |
| **Mutation Score Target** | ≥ {70%} |
| **Mutant Types** | {Arithmetic, Conditional, Return Value, String} |

### 6.2 Mutation Results

| Module | Mutants Generated | Killed | Survived | Score | Action for Survivors |
|---|---|---|---|---|---|
| `{module}` | {100} | {85} | {15} | {85%} | {Add edge case tests for lines X, Y} |
