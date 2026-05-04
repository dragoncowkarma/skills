# Agent Workflow & Task Generation Guidelines

## 1. Prompt Generation & Context Reduction
* **Lightweight Prompt Generation**: When generating individual task prompts (`.md`), do not use XML tags. Write only the pure 'variable context' in Markdown, excluding common rules.
* **Symbol Targeting**: When writing the `<work_scope>`, specify reference files at the function or class name level (e.g., `auth.py::verify_token()`), not the full file path.
* **Dynamic Validation Commands**: When generating `Execution Steps`, strictly inject specific terminal commands tailored to the project environment (e.g., `pytest tests/`, `npm run build`).

## 2. 4-Tier Cascading AGENTS.md Architecture
Create and maintain 4 router rulebooks with separated roles by depth to execute and manage prompts.
* **`/AGENTS.md`**: Project root access control and traffic routing.
* **`/docs/AGENTS.md`**: Standardization of documents (planning, diagrams) and master list updates.
* **`/docs/prompts/AGENTS.md`**: The `[Base Profile] + [Individual Task]` assembly protocol and parallel execution control.
* **`/xxx/AGENTS.md`**: Tech stack and convention linting inside specific code modules (e.g., `src/`, `app/`).

## 3. Directory Structure
* Planning & Task Lists: `docs/[domain]/` (`01_xxx.md`, `99_xxx.md`)
* Common Base Profiles: `docs/prompts/profiles/[agent]_base.md`
* Individual Task Prompts: `docs/prompts/[agent]_[task_name]_[UID].md`
* Parallel Dashboard: `docs/prompts/parallel_execution_manifest.md`
