# Installation and GitHub setup

The kit is a provider-neutral framework template. Install it at an application's repository root, or copy the framework files into the application repository. It currently targets Flutter and Android release workflows.

## Local installation

```bash
cp framework.env.example framework.env
```

Set `ANDROID_PACKAGE_NAME` to the real application ID. Keep `framework.env`, signing files, and service-account JSON outside Git. The example deliberately uses `com.example.app` so an accidental upload fails closed.

## Codebase memory

Register `codebase-memory-mcp` in Codex and the executor client. The graph is read-first structural memory; persist plans, approvals, and QA evidence under `releases/` instead.

## Physical devices

Run device QA on an isolated self-hosted runner with `adb`, Flutter, and a dedicated physical Android device. Hosted GitHub runners cannot access USB devices.

## Play Internal Testing

The upload script supports a service-account OAuth flow and refuses the `production` track. Before enabling it, create a service account with minimum Android Publisher access, store its JSON in a GitHub secret or ignored local path, use the Internal Testing track, and test with a non-production application. Never place credentials in this repository.

## Publishing this framework

The canonical public repository is [andika-vibe-code/bounded-agent-release-kit](https://github.com/andika-vibe-code/bounded-agent-release-kit). To publish a fork or a new copy, create an empty public GitHub repository, then run:

```bash
git init
git branch -M main
git add .
git commit -m "feat: initial framework"
git remote add origin https://github.com/YOUR_ACCOUNT/bounded-agent-release-kit.git
git push -u origin main
```

Before pushing, run the same checks used by CI:

```bash
bash -n scripts/*.sh
test -f README.md && test -f framework.env.example
```

Never commit `framework.env`, credentials, generated release state, or application-specific code.
