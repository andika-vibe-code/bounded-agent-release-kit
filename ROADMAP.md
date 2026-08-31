# Roadmap

This roadmap describes the public framework, not any private application built with it. Priorities may change as contributors report real-world use.

## v0.1 — foundation

- [x] Provider-neutral planner and executor contract
- [x] Approval lock and release-state layout
- [x] Shell-based release gates
- [x] Optional device QA and Play Internal Testing upload path
- [x] Public security and contribution boundaries

## v0.2 — easier adoption

- [ ] Add a small, self-contained sample Flutter fixture
- [ ] Add automated tests for success and failure paths of each script
- [ ] Add documented examples of `implementation_plan.md` and `qa_report.md`
- [ ] Add a dry-run mode for release and upload commands
- [ ] Add compatibility notes for macOS, Linux, and hosted/self-hosted runners

## v0.3 — stronger integrations

- [ ] Add opt-in GitHub Actions release workflow templates
- [ ] Add structured validation for release artifacts
- [ ] Add pluggable QA evidence adapters
- [ ] Add maintainer documentation for reviewing bounded executor changes

## How to influence the roadmap

Open an issue describing the problem, the environment, the smallest reproducible example, and whether you would be able to test a proposed fix. Pull requests are welcome for focused changes that preserve the provider-neutral boundary.
