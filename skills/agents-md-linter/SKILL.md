---
name: agents-md-linter
description: Protocol integrity checker for AGENTS.md and rule documents.
license: MIT
compatibility: python3
metadata:
  author: dragoncowkarma
  version: "1.0.0"
allowed-tools: bash(./scripts/lint.sh)
---

# Agents md linter

This skill ensures `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` adhere to established protocol standards. It identifies patterns that impact execution reliability and provides a quality score.

## When to use
- Use when only `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` are created or updated.
- Use to verify if instructions are actionable or contain ambiguous directives.
- Use to audit project governance files for anti-patterns before execution.

## Prerequisites & Setup
- **Python 3**: Required to run the core linter script.
- **Bash Shell**: Required for the `lint.sh` wrapper.
- **Permissions**: Ensure `./scripts/lint.sh` is executable (`chmod +x`).

## Workflow
1. **Target Selection**: Identify the rule document (e.g., `AGENTS.md`).
2. **Analysis**: Execute `./scripts/lint.sh <file_path>`.
3. **Evaluation**:
   - **Score >= 70**: [Pass] Follows working patterns.
   - **Score 40-69**: [Warning] Identified anti-patterns; minor rework needed.
   - **Score < 40**: [Fail] Significant issues; instructions may be ignored or cause confusion.
4. **Correction**: Address identified anti-patterns (e.g., prioritize lists, add `ruff check` for style guides).

## Guardrails & Execution Notes
- **Conditional Run**: The linter is configured to only execute for `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md`. Other file types are skipped.
- **Actionable Only**: Focus on improving "Command-first instructions" and "Closure definitions".
- **Safety First**: Look for "Escalation rules" (e.g., `if...stop`) to ensure agent safety.

## References
- [Agents MD Patterns - Blake Crosley](https://blakecrosley.com/blog/agents-md-patterns)
