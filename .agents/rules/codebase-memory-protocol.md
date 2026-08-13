# Codebase Memory Protocol

Codebase Memory MCP is shared structural memory. It stores code relationships, not planning conversations.

1. Use `get_architecture` for an unfamiliar subsystem, `search_graph` to find a symbol, and `trace_path` before changing a public behavior.
2. Resolve a qualified name before `get_code_snippet`. Use `query_graph` only for a bounded impact question.
3. Use text search only for literals, configuration, or when the graph lacks coverage.
4. Refresh with `index_repository(mode="fast", persistence=true)` only when the graph is stale, before a release plan, or after a merged release.
5. Never place prompts, plans, TODOs, execution status, or model opinions in the graph. Store those in versioned release artifacts.
6. If graph output disagrees with source or tests, source and tests win; record the discrepancy in the release artifact.
