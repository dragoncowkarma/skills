# 🛠️ MODULE DEVELOPMENT RULES (<ModuleName>)

## When Writing Code
- Priority 1: Verify local dependencies using `cat package.json`.
- Priority 2: Isolate module logic and avoid cross-domain imports.
- Priority 3: Run local module tests using `npm run test:<module>`.

## When Managing State
- Priority 1: Check existing state management patterns via `grep -r "useState" .`.
- Priority 2: Add new state only if existing stores cannot be reused.
- Priority 3: Validate state changes using `npm run lint`.

## When Blocked
- If module dependencies conflict: stop and run `npm ls`.
- Never: modify files outside this specific module's directory (`../`).

## Definition of Done
- Module task is complete when ALL of the following pass:
- Priority 1: Module-specific tests `npm run test` exits 0.
- Priority 2: Type checker `tsc --noEmit` exits 0.
