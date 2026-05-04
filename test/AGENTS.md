# 🌍 GLOBAL AGENT MANIFESTO (Root)

## When Starting Session
- Priority 1: Verify current directory matches project root using `pwd`.
- Priority 2: List available domain contexts using `ls docs/`.
- Priority 3: Check overall project health running `npm run build`.

## When Routing Tasks
- Priority 1: Document changes must use `docs/AGENTS.md` rules.
- Priority 2: Code execution uses `docs/prompts/AGENTS.md`.
- Priority 3: Module code uses local `<module>/AGENTS.md` rules.

## When Blocked
- If instructions conflict: stop and request clarification.
- Never: delete root configurations like `package.json` or `build.gradle.kts`.

## Definition of Done
- Task is complete when ALL of the following pass:
- Priority 1: Agent navigated to correct directory via `cd`.
- Priority 2: Target routing script exits 0.

## Self-Healing
- If an error occurs, the agent must run `git restore .` to revert changes and halt the task.