# Troubleshooting Log

> **Project**: {PROJECT_NAME}
> **Last Updated**: {DATE}
> **Maintainer**: {MAINTAINER}

---

## Quick Start

1. Log every non-trivial error encountered during development — not just the fix, but the journey
2. Assign severity (P0-P3) and searchable tags immediately
3. Document ALL attempted solutions, including failed ones — this prevents future teams from repeating mistakes
4. Link to related task IDs, cycle logs, and ADRs
5. Search this document first before debugging a new issue

---

## Severity Classification

| Severity | Definition | Response Time | Escalation |
|---|---|---|---|
| **P0 — Critical** | System down, data loss risk, security breach | Immediate (< 1h) | {Escalation contact} |
| **P1 — High** | Major feature broken, no workaround | Same day (< 4h) | {Team lead} |
| **P2 — Medium** | Feature degraded, workaround available | Within sprint | {Sprint planning} |
| **P3 — Low** | Cosmetic, minor inconvenience | Best effort | {Backlog} |

---

## Tag Taxonomy

Use these tags for searchability. Combine multiple tags per entry.

| Category | Tags |
|---|---|
| **Component** | `#backend` `#frontend` `#database` `#infra` `#ci-cd` `#harness` `#agent` |
| **Error Type** | `#build-failure` `#runtime-error` `#test-failure` `#coverage-gap` `#timeout` `#memory-leak` `#permission` `#dependency` |
| **Root Cause** | `#config-error` `#race-condition` `#missing-dep` `#version-mismatch` `#api-change` `#data-corruption` `#env-diff` |
| **Agent-Specific** | `#agent-loop` `#hallucination` `#scope-violation` `#integrity-violation` `#cycle-log-stale` |

---

## Incident Log

### Entry Template

> Copy this block for each incident:

---

### INC-{NNN}: {Brief Title}

| Attribute | Value |
|---|---|
| **Date** | {DATE} |
| **Severity** | {P0 / P1 / P2 / P3} |
| **Tags** | {#tag1 #tag2 #tag3} |
| **Reporter** | {Name / Agent} |
| **Task ID** | {TASK-XXX or N/A} |
| **Environment** | {Development / CI / Staging / Production} |
| **Status** | {Open / Investigating / Resolved / Won't Fix} |
| **Resolution Time** | {Nh / Nd} |

#### Symptom

{What was observed? Error messages, unexpected behavior, stack traces.}

```
{Paste relevant error output / stack trace here}
```

#### Context

- **What was being done**: {What task/action triggered the error}
- **Recent changes**: {What changed recently that might be related}
- **Frequency**: {Always / Intermittent / Once}
- **Impact**: {Who/what is affected}

#### Root Cause Analysis

{After investigation, what was the actual underlying cause?}

**Why-Why-Why Chain** (5 Whys):
1. Why did {symptom} occur? → Because {cause 1}
2. Why did {cause 1} occur? → Because {cause 2}
3. Why did {cause 2} occur? → Because {root cause}

#### Attempted Solutions Timeline

| # | Date/Time | Attempted Solution | Result | Time Spent |
|---|---|---|---|---|
| 1 | {DATETIME} | {First thing tried} | ❌ {Why it didn't work} | {30m} |
| 2 | {DATETIME} | {Second thing tried} | ❌ {Why it didn't work} | {1h} |
| 3 | {DATETIME} | {Final solution} | ✅ {How it resolved the issue} | {15m} |

#### Resolution

{Detailed description of the final fix. Include code snippets, config changes, or commands.}

```diff
- old_broken_code()
+ new_fixed_code()
```

**Commit**: `{commit_sha}` — `{commit message}`

#### Prevention Measures

- {What was done to prevent recurrence}
- {Test case added: TC-XXX-NNN}
- {Monitoring/alert added}
- {Documentation updated}
- {ADR created: ADR-{NNN}}

#### Lessons Learned

{What would you tell someone who encounters this issue in the future?}

---

### INC-001: {Example — First Incident}

*(Use template above)*

---

## Summary Statistics

### Incidents by Severity

| Severity | Open | Resolved | Total | Avg Resolution Time |
|---|---|---|---|---|
| P0 | {0} | {0} | {0} | {—} |
| P1 | {0} | {0} | {0} | {—} |
| P2 | {0} | {0} | {0} | {—} |
| P3 | {0} | {0} | {0} | {—} |

### Incidents by Tag (Top 10)

| Tag | Count | Most Common Root Cause |
|---|---|---|
| {#tag} | {N} | {root cause pattern} |

### Monthly Trend

| Month | New Incidents | Resolved | Net Open | Avg Resolution Time |
|---|---|---|---|---|
| {YYYY-MM} | {N} | {N} | {N} | {Nh} |

---

## Known Issues (Active)

| INC ID | Severity | Title | Workaround | ETA for Fix |
|---|---|---|---|---|
| INC-{NNN} | {P2} | {Brief title} | {Describe workaround} | {DATE or TBD} |

---

## Related Documents

| Document | Path | Relationship |
|---|---|---|
| Software Test Report | `docs/testing/STR.md` | Test failure details |
| Kanban Board | `docs/agile/KANBAN.md` | Blocked task tracking |
| Architecture Decision Records | `docs/decisions/ADR-*.md` | Decisions made from incidents |
| Cycle Logs | `docs/cycle_logs/*.md` | Agent reasoning during failures |
