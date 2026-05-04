# 📐 PLANNING AGENT RULES (Docs)

## When Writing Documentation
- Priority 1: Validate all mermaid diagrams using `mmdc -i file.md`.
- Priority 2: Enforce markdown style guide running `prettier --write .`
- Priority 3: Check naming conventions using `textlint docs/`.

## When Updating Master List
- Priority 1: Read `99_master_task_list.md` via `cat`.
- Priority 2: Update task status to `[x]` if complete.
- Priority 3: Save changes and run `git add docs/`.

## When Blocked
- If domain architecture is missing: stop and ask user.
- Never: overwrite `01_architecture.md` without explicit approval.

## Definition of Done
- Documentation task is complete when ALL of the following pass:
- Priority 1: Markdown linter `prettier --check docs/` exits 0.
- Priority 2: Diagram compiler `mmdc` exits 0.
