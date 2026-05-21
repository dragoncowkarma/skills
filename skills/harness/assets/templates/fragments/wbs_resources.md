## 6. Resource Allocation

### 6.1 Resource Matrix

| Resource | Type | Availability | Assigned Phases | Max Concurrent Tasks |
|---|---|---|---|---|
| {Lead Developer} | Human | Full-time | P-001, P-003, P-004 | 2 |
| {QA Agent} | Agent (QA) | On-demand | P-002 (RED), P-003 | 3 (per WIP limit) |
| {DEV Agent} | Agent (DEV) | On-demand | P-002 (GREEN) | 3 (per WIP limit) |
| {DOC Agent} | Agent (DOC) | On-demand | P-002 (DOC), P-004 | 3 (per WIP limit) |

### 6.2 Workload Distribution

| Assignee Type | Total Tasks | Total Estimated Hours | % of Total Effort |
|---|---|---|---|
| Human | {N} | {N}h | {N}% |
| Agent (QA) | {N} | {N}h | {N}% |
| Agent (DEV) | {N} | {N}h | {N}% |
| Agent (DOC) | {N} | {N}h | {N}% |
| **Total** | **{N}** | **{N}h** | **100%** |

---

## 7. Estimation Summary

### 7.1 Effort Summary by Phase

| Phase | Tasks | Sub-tasks | Estimated Hours | Human Hours | Agent Hours |
|---|---|---|---|---|---|
| P-001: Planning | {N} | — | {N}h | {N}h | {N}h |
| P-002: Development | {N} | {N} | {N}h | {N}h | {N}h |
| P-003: Testing | {N} | — | {N}h | {N}h | {N}h |
| P-004: Deployment | {N} | — | {N}h | {N}h | {N}h |
| **Total** | **{N}** | **{N}** | **{N}h** | **{N}h** | **{N}h** |

### 7.2 Critical Path

The longest dependency chain determines the minimum project duration:

```
T-001-001 → T-001-002 → T-002-001 → T-002-002 → T-002-003 → T-003-001 → T-003-005 → T-004-001 → T-004-003
```

**Critical Path Duration**: {N} days

### 7.3 Risk Buffer

| Risk | Impact | Probability | Buffer Allocation |
|---|---|---|---|
| Agent retry loops | +2h per task | Medium | 20% buffer on Agent tasks |
| Requirement changes | Rework of Phase 2 | Low | 10% buffer on total |
| Coverage gaps | Additional test cycles | Medium | 1 extra day in Phase 3 |

---

## 8. Revision History

| Version | Date | Author | Description |
|---|---|---|---|
| 0.1.0 | {DATE} | {AUTHOR} | Initial WBS draft |

---

## 9. Related Documents

| Document | Path | Relationship |
|---|---|---|
| Software Requirements Specification | `docs/specs/SRS.md` | Requirements being decomposed |
| Software Design Document | `docs/specs/SDD.md` | Architecture guiding task structure |
| Kanban Board | `docs/agile/KANBAN.md` | Real-time task status (SSOT view) |
| Scrum Sprint Tracking | `docs/agile/SCRUM.md` | Sprint-level planning |
| Task Registry | `docs/tasks/*.json` | Harness task state (source of truth) |
| Quality Metrics | `docs/quality_metrics.md` | Automated quality reporting |
