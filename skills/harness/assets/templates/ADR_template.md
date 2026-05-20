# Architecture Decision Record (ADR)

> **ADR ID**: ADR-{NNN}
> **Title**: {Decision Title}
> **Date**: {DATE}
> **Status**: Proposed | Accepted | Deprecated | Superseded by [ADR-{NNN}]
> **Deciders**: {List of people/agents who made this decision}

---

## Quick Start

1. Create one ADR per significant architectural decision
2. ADRs are **immutable once Accepted** — to change a decision, create a new ADR that supersedes it
3. Number ADRs sequentially: ADR-001, ADR-002, etc.
4. Link ADRs from [SDD](../specs/SDD.md) and [SRS](../specs/SRS.md) requirement traceability

---

## Context

Describe the situation that requires a decision. Include:

- **Background**: What is the technical/business context?
- **Problem Statement**: What specific problem needs solving?
- **Constraints**: What limitations exist? (budget, timeline, team skill, existing tech)
- **Driving Requirements**: Which SRS requirements drive this decision?
  - REQ-{MODULE}-{NNN}: {Brief description}

---

## Decision Drivers

Rank the factors that influenced this decision (most important first):

1. **{Factor 1}**: {e.g., "Performance under high concurrency" — Weight: Critical}
2. **{Factor 2}**: {e.g., "Team familiarity with technology" — Weight: High}
3. **{Factor 3}**: {e.g., "Long-term maintenance cost" — Weight: Medium}
4. **{Factor 4}**: {e.g., "Community support and ecosystem" — Weight: Low}

---

## Considered Options

### Option A: {Option Name}

**Description**: {What this option involves}

| Pros | Cons |
|---|---|
| {Advantage 1} | {Disadvantage 1} |
| {Advantage 2} | {Disadvantage 2} |

**Estimated Effort**: {S/M/L/XL}
**Risk Level**: {Low / Medium / High}

### Option B: {Option Name}

**Description**: {What this option involves}

| Pros | Cons |
|---|---|
| {Advantage 1} | {Disadvantage 1} |
| {Advantage 2} | {Disadvantage 2} |

**Estimated Effort**: {S/M/L/XL}
**Risk Level**: {Low / Medium / High}

### Option C: {Option Name} *(if applicable)*

**Description**: {What this option involves}

| Pros | Cons |
|---|---|
| {Advantage 1} | {Disadvantage 1} |

---

## Decision

**Chosen Option**: {Option X}

**Rationale**: {Explain WHY this option was chosen over alternatives. Reference the decision drivers above. Be specific about what tipped the balance.}

**Trade-offs Accepted**:
- {What we sacrifice by choosing this option}
- {What risks we accept}

---

## Consequences

### Positive

- {What improves as a result of this decision}
- {What becomes easier or more efficient}

### Negative

- {What becomes harder or more constrained}
- {What technical debt is introduced}

### Neutral

- {Side effects that are neither positive nor negative}

---

## Implementation Notes

- **Affected Components**: {List components from [SDD](../specs/SDD.md) that change}
- **Migration Required**: {Yes / No — describe if yes}
- **Reversibility**: {Easy / Difficult / Irreversible}
- **Validation**: {How will we verify this decision was correct? Metrics to track.}

---

## Follow-up Actions

| Action | Owner | Due Date | Status |
|---|---|---|---|
| {Implement chosen option} | {Name/Agent} | {DATE} | {To Do / Done} |
| {Update SDD to reflect decision} | {Name} | {DATE} | {To Do} |
| {Monitor metrics for validation} | {Name} | {DATE + 30d} | {To Do} |

---

## Actual Consequences (Post-Implementation Review)

> Fill this section 2-4 weeks after implementation to track whether predictions were accurate.

| Predicted Consequence | Actual Outcome | Accuracy |
|---|---|---|
| {Positive: improved performance} | {Measured: 40% latency reduction} | ✅ Confirmed |
| {Negative: increased memory usage} | {Measured: 15% increase, within budget} | ✅ Confirmed |
| {Risk: migration downtime} | {Actual: zero downtime} | ⬆️ Better than expected |

**Would we make the same decision again?** {Yes / No — explain}

---

## Related Documents

| Document | Path | Relationship |
|---|---|---|
| Software Design Document | `docs/specs/SDD.md` | Design implementing this decision |
| Software Requirements Specification | `docs/specs/SRS.md` | Requirements driving this decision |
| Previous ADR | `docs/decisions/ADR-{NNN-1}.md` | Related/superseded decision |
