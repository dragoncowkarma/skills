## 4. Functional Requirements

### 4.1 Requirement Template

> Copy this block for each requirement:

#### REQ-{MODULE}-{NNN}: {Requirement Title}

| Attribute | Value |
|---|---|
| **ID** | REQ-{MODULE}-{NNN} |
| **Priority** | P0 (Critical) / P1 (High) / P2 (Medium) / P3 (Low) |
| **Source** | {Stakeholder name / Planning doc reference} |
| **Status** | Proposed / Approved / Implemented / Verified / Deferred |
| **Depends On** | {REQ-XXX-NNN or "None"} |

**Description**: {One clear sentence describing WHAT the system must do.}

**Rationale**: {WHY this requirement exists. What business value does it provide?}

**Acceptance Criteria**:
1. GIVEN {precondition}, WHEN {action}, THEN {expected result}
2. GIVEN {precondition}, WHEN {action}, THEN {expected result}

**Edge Cases**:
- {What happens if input is null/empty?}
- {What happens under concurrent access?}
- {What happens at boundary values?}

**Test Case Link**: [TC-{MODULE}-{NNN}](../testing/STD.md#tc-module-nnn)

---

### 4.2 Module: {Module Name}

#### REQ-{MODULE}-001: {First Requirement}

*(Use template from 4.1)*

#### REQ-{MODULE}-002: {Second Requirement}

*(Use template from 4.1)*
