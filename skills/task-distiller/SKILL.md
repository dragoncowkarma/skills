---
name: task-distiller
description: Parse planning documents to generate lightweight, executable AI agent task prompts, orchestrated by a 4-tier Cascading AGENTS.md Architecture.
license: MIT
metadata:
  author: dragoncowkarma
  version: "1.0.0"
  short-description: Core prompt generator with 4-tier cascading routing.
---

# Build Agent Workflow Skill

The core purpose of this skill is to **parse planning documents (natural language) and generate lightweight, immediately executable task prompts (commands) for AI agents**. The generated prompts are safely orchestrated by a cascading rule system.

## Workflow & Core Rules

1. **[Planning Analysis & Master List Splitting]**:
   - Analyze planning documents under `docs/` to divide the system into domain units.
   - Identify dependencies (DAG), list individual tasks in `99_master_task_list.md`, and assign appropriate agents (Jules, Antigravity, etc.) and models.

2. **[🎯 Core: Lightweight Task Prompt Generation]**:
   - For each task defined in the master list, generate the actual prompt file (`docs/prompts/<agent>_<task>_<id>.md`) based on `assets/task_template.md`.
   - **Generation Principle**: Never include prose or duplicated system rules inside the prompt. Refine it to include ONLY: ① `Target` (file path to modify), ② `Read-Only` (reference symbol signatures), and ③ Dynamically injected `Validation Commands` (e.g., `pytest`, `npm test`).

3. **[4-Tier Cascading AGENTS.md Architecture]**:
   - When generated prompts are executed, the agent's context is controlled based on the directory depth.
   - Four rulebooks strictly govern agent behavior: `/AGENTS.md` (Global), `/docs/AGENTS.md` (Planning), `/docs/prompts/AGENTS.md` (Execution), and `/xxx/AGENTS.md` (Module Stack).

4. **[Anti-Pattern Control & Self-Healing]**:
   - All generated prompts and `AGENTS.md` files must exclude ambiguous instructions, enforce `Priority X:` based directives, and use explicit `exits 0` closure conditions.
   - Perform Self-Healing by rolling back with `git restore` upon task failure.
