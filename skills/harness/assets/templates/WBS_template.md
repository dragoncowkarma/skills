# Work Breakdown Structure (WBS)

> **Document ID**: WBS-{PROJECT_ID}-001
> **Version**: 0.1.0 (Draft)
> **Last Updated**: {DATE}
> **Author**: {AUTHOR}
> **Status**: Draft | In Review | Approved | Superseded

---

## Quick Start

1. Break work into **Phase → Task → Sub-task** hierarchy (max 3 levels)
2. Every item MUST have a unique Task ID matching `docs/tasks/{task_id}.json`
3. Assign each item to either `Human` or `Agent` (or specific sub-agent: `QA`, `DEV`, `DOC`)
4. Define dependencies BEFORE starting work — no circular dependencies allowed
5. Update status as work progresses: `Not Started` → `In Progress` → `Completed` → `Verified`

---

## Master Index & Lazy-Loading Fragments

AI agents should read only the relevant fragment(s) below to reduce context size.

- **[Section 1 & 2: WBS Overview & Dictionary](fragments/wbs_overview.md)**
  - Purpose, numbering conventions, status definitions, and WBS work package dictionary template.
- **[Section 3: Work Breakdown Tables](fragments/wbs_tasks.md)**
  - Phase breakdown, task assignees, estimates, dependencies, and sub-task tables.
- **[Section 4 & 5: Dependency Graph & Gantt Chart](fragments/wbs_schedule.md)**
  - Mermaid diagrams for visual dependency routing and project schedules.
- **[Section 6, 7, 8, & 9: Resources, Estimation, Revision History & Related Docs](fragments/wbs_resources.md)**
  - Resource matrices, effort analysis, critical path, risk buffers, revisions, and relationships.

---

## Harness Integration

### Task JSON Mapping

Each WBS task should have a corresponding `docs/tasks/{task_id}.json` entry:

| WBS Field | Task JSON Field |
|---|---|
| Task ID | `.id` |
| Assignee | `.assigned_sub_agent` |
| Status | `.status` |
| Dependencies | `.depends_on` |
| Estimated Hours | `.estimated_hours` (optional) |

### Workflow

1. **Create WBS** → Define all phases, tasks, and sub-tasks
2. **Generate Task JSONs** → `harness.sh docs-init` + create task files for each WBS item
3. **Execute** → Follow RED→GREEN→DOC cycle per task, in dependency order
4. **Track** → Run `harness.sh kanban-render` to update the live Kanban view
5. **Report** → Run `harness.sh document --standard QUALITY_METRICS` for quality metrics
