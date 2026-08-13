# Bounded Agent Release Kit

Provider-neutral release orchestration for Flutter and Android projects that use a long-context planner, bounded coding executor, physical-device QA, and optional Google Play Internal Testing uploads.

The kit keeps structural code knowledge, task state, and agent conversations separate so a model change or a long task does not silently change scope.

## What it provides

- A read-first `codebase-memory-mcp` protocol for Codex, fallback planners, and executors.
- A compact plan/handoff contract that limits executor scope and context.
- Release gates for plan approval, automated QA, and optional physical-device evidence.
- Scripts for building an AAB/APK and optionally uploading an AAB to Play Internal Testing with a service account.
- GitHub Actions templates for analysis, release builds, and a self-hosted physical-device runner.

## Quick start

1. Copy this kit into the root of a Flutter repository, or copy `framework.env.example` to `framework.env` and set the Android package ID.
2. Register `codebase-memory-mcp` in the local Codex and executor clients.
3. Create a release brief:

   ```bash
   cp framework.env.example framework.env
   scripts/orchestrate_release.sh init v0.1.0+1 "Describe the release objective"
   ```

4. Have the planner create `releases/v0.1.0+1/implementation_plan.md` from the brief. Review it, then unlock and validate it:

   ```bash
   scripts/approve.sh v0.1.0+1
   scripts/orchestrate_release.sh validate v0.1.0+1
   ```

5. Run QA and release only after the required evidence exists:

   ```bash
   scripts/orchestrate_release.sh device-qa v0.1.0+1
   DEVICE_QA_REQUIRED=1 scripts/orchestrate_release.sh release v0.1.0+1
   ```

Read [the installation guide](docs/INSTALL.md) before enabling Play uploads. The scripts never create a Play service account, publish to production, or automate a graphical agent.

## Repository boundaries

This repository must not contain application source code, Firebase configuration, keystores, service-account JSON, real release binaries, private codebase-memory artifacts, or copied model transcripts.

## Status

Early public template. Use a test application and the Internal Testing track before relying on it for production releases.
