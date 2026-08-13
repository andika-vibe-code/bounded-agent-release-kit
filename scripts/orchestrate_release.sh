#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
[[ -f framework.env ]] && source framework.env
app_root="${APP_ROOT:-.}"
releases_dir="${RELEASES_DIR:-releases}"

usage() {
  echo "Usage: scripts/orchestrate_release.sh {init|validate|device-qa|release} vX.Y.Z+N [objective]" >&2
}

[[ $# -ge 2 ]] || { usage; exit 2; }
command_name="$1"
release_ref="${2#releases/}"
release_ref="${release_ref%/}"
[[ "$release_ref" =~ ^v[0-9]+[.][0-9]+[.][0-9]+[+][0-9]+$ ]] || { echo "Invalid release reference: $release_ref" >&2; exit 2; }
release_dir="$releases_dir/$release_ref"
brief="$release_dir/orchestrator_brief.md"
plan="$release_dir/implementation_plan.md"
lock="$release_dir/.approval-lock"

init_release() {
  [[ $# -eq 3 ]] || { usage; exit 2; }
  [[ ! -e "$brief" ]] || { echo "Refusing to overwrite $brief" >&2; exit 1; }
  mkdir -p "$release_dir"
  cat >"$brief" <<EOF
# Orchestrator Brief — $release_ref

## Objective

$3

## Required plan

- Scope and non-goals
- Exact file allowlist
- Acceptance tests and rollback conditions
- Bounded executor handoff with stop/escalation conditions
EOF
  printf '%s\n' 'Review the brief and plan before approval.' >"$lock"
  echo "Created $brief"
}

validate_plan() {
  [[ ! -f "$lock" ]] || { echo "Approval lock is active: $lock" >&2; exit 12; }
  [[ -f "$brief" && -f "$plan" ]] || { echo "Brief or plan missing in $release_dir" >&2; exit 1; }
  for heading in Scope Non-goal Acceptance coder-handoff; do
    rg -qi "$heading" "$plan" || { echo "Plan missing: $heading" >&2; exit 1; }
  done
  echo "Validated $plan"
}

case "$command_name" in
  init) init_release "$@" ;;
  validate) validate_plan ;;
  device-qa) validate_plan; bash scripts/device_qa.sh "$release_ref" ;;
  release)
    validate_plan
    [[ -f "$release_dir/qa_report.md" ]] && rg -q 'Auto QA Status:[[:space:]]*PASS' "$release_dir/qa_report.md" || { echo "Auto QA gate failed" >&2; exit 20; }
    if [[ "${DEVICE_QA_REQUIRED:-0}" == 1 ]]; then
      [[ -f "$release_dir/device_qa/status.json" ]] && rg -q '"status": "PASS"' "$release_dir/device_qa/status.json" || { echo "Device QA gate failed" >&2; exit 21; }
    fi
    (cd "$app_root" && flutter build appbundle --release && flutter build apk --release)
    mkdir -p "$release_dir/build"
    cp "$app_root/build/app/outputs/bundle/release/app-release.aab" "$release_dir/build/"
    cp "$app_root/build/app/outputs/flutter-apk/app-release.apk" "$release_dir/build/"
    if [[ "${PLAY_UPLOAD_ENABLED:-0}" == 1 ]]; then
      bash scripts/upload_play_internal.sh "$release_ref"
    fi
    ;;
  *) usage; exit 2 ;;
esac
