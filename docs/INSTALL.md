# Installation and GitHub setup

Install the kit at an application's repository root, then copy `framework.env.example` to `framework.env`. Set `ANDROID_PACKAGE_NAME` to the target application ID. Keep `framework.env`, signing files, and service-account JSON outside Git.

## Codebase memory

Register `codebase-memory-mcp` in Codex and the executor client. The graph is read-first structural memory; persist plans, approvals, and QA evidence under `releases/` instead.

## Physical devices

Run device QA on an isolated self-hosted runner with `adb`, Flutter, and a dedicated physical Android device. Hosted GitHub runners cannot access USB devices.

## Play Internal Testing

The upload script supports a service-account OAuth flow and refuses the `production` track. Before enabling it, create a service account with minimum Android Publisher access, store its JSON in a GitHub secret or ignored local path, use the Internal Testing track, and test with a non-production application. Never place credentials in this repository.

## Publishing this framework

Create an empty public GitHub repository, then run:

```bash
git init
git branch -M main
git add .
git commit -m "feat: initial framework"
git remote add origin https://github.com/YOUR_ACCOUNT/bounded-agent-release-kit.git
git push -u origin main
```
