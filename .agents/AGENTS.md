# Bounded Agent Release Kit

## Roles

| Role | Responsibility | Must not do |
|---|---|---|
| Planner (Codex or equivalent) | Scope, plan, review, escalation | Write executor transcripts into durable memory |
| Capacity fallback planner | Resume only after a confirmed capacity limit | Change scope while resuming |
| Executor (Antigravity or equivalent) | Bounded implementation and evidence | Plan a new feature or edit outside the allowlist |
| Release scripts and CI | Deterministic gates | Invent QA evidence |

## Core directives

1. Use `codebase-memory-mcp` read-first for symbols, call paths, and architecture. Source and tests remain authoritative.
2. Persist scope and phase state in `releases/vX.Y.Z+N/`, not in model conversations.
3. Every plan needs scope, non-goals, file allowlist, acceptance tests, rollback conditions, and a bounded executor handoff.
4. A fallback planner may switch only for a quota, rate, or context limit—not a test, tool, or scope disagreement.
5. Physical-device QA is required only when the release policy enables it; never fabricate connected-device evidence.

Read `rules/codebase-memory-protocol.md` and `rules/handoff-contract.md` before using the scripts.
