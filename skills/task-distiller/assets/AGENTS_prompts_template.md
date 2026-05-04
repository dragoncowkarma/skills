# 🚀 EXECUTION & ROUTING PROTOCOL (Prompts)

## When Assembling Prompts
- Priority 1: Read base profile using `cat profiles/<agent>_base.md`.
- Priority 2: Read specific task using `cat <agent>_<task>_<id>.md`.
- Priority 3: Combine and execute via `python run_agent.py`.

## When Executing Parallel Tasks
- Priority 1: Check `parallel_execution_manifest.md` for locks.
- Priority 2: Verify target isolation using `grep -r "Target"`.
- Priority 3: Execute batch using `make run-parallel`.

## When Blocked
- If execution fails twice: stop and run `git restore .`
- Never: force push or skip test validations to bypass errors.

## Definition of Done
- Execution is complete when ALL of the following pass:
- Priority 1: Automated tests `pytest tests/` exits 0.
- Priority 2: Local linter `ruff check .` exits 0.
