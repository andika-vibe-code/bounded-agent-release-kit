# Bounded Handoff Contract

Every executor handoff contains an objective, non-goals, a file allowlist, acceptance tests, artifact paths, and a stop/escalation condition.

## Required planner artifacts

- `releases/vX.Y.Z+N/orchestrator_brief.md`
- `releases/vX.Y.Z+N/implementation_plan.md`
- `releases/vX.Y.Z+N/.orchestrator-state.json` (generated, local by default)

## Executor acknowledgement

Before editing, the executor must save `coder_ack.md` with these headings:

```text
ACK:
FILES:
FIRST_STEPS:
BLOCKERS:
```

If scope, allowlist, or acceptance criteria are incomplete, save `escalation.md` and stop. On completion, save a compact phase status file with modified files, test evidence, and the next recommended phase. Do not pass whole prior chats between agents.
