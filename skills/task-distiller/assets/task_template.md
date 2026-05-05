# Task Context
- **Task ID**: [e.g., A1B2 (implement_login)]
- **Handoff Note from [Dependency ID]**: 
  > *[Insert Delta Note from previous worker. If none, write None]*

## Work Scope
- **Target**: `[Exact file path to modify]`
- **Read-Only (Symbols)**:
  - `[File and function name to reference. e.g., src/utils/jwt.py::generate_token()]`
- **Context Command**: `[e.g., grep -A 10 "def generate_token" src/utils/jwt.py]`

## Execution Steps
1. **[Explore]**: Extract only the necessary symbol signatures using the Context Command.
2. **[Implement]**: Implement the core logic inside the Target file according to the planning document requirements.
3. **[Validate]**: Upon completion, run the following command in the terminal to prove the working state.
   - `[Inject dynamic validation command. e.g., pytest tests/api/test_auth.py]`
