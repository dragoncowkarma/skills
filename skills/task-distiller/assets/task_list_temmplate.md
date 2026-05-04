# 📋 Master Task List

## 1. Task Meta & Execution Status

| Task ID | Task Name | Target Agent | Target Model | Depends On | Parallel Mode | Prompt File Path | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| UID1 | example_task | antigravity | claude sonnet 4.6 | None | Disabled | `docs/prompts/antigravity_example_task_UID1.md` | [ ] |
| UID2 | example_parallel| jules | default | UID1 | Enabled (Batch 1) | `docs/prompts/jules_example_parallel_UID2.md` | [ ] |

## 2. Execution Flow
1. **[Sequential]** Execute `UID1` sequentially first.
2. **[Parallel]** Execute `UID2` and others in parallel (Batch 1).
