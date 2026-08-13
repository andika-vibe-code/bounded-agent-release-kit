#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 vX.Y.Z+N" >&2
  exit 2
fi

release_ref="${1#releases/}"
release_ref="${release_ref%/}"
lock_file="${RELEASES_DIR:-releases}/$release_ref/.approval-lock"
[[ -f "$lock_file" ]] || { echo "No approval lock found: $lock_file" >&2; exit 1; }
rm "$lock_file"
echo "Approved $release_ref"
