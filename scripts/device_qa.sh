#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
[[ -f framework.env ]] && source framework.env
[[ $# -eq 1 ]] || { echo "Usage: $0 vX.Y.Z+N" >&2; exit 2; }

release_ref="${1#releases/}"
release_ref="${release_ref%/}"
[[ "$release_ref" =~ ^v[0-9]+[.][0-9]+[.][0-9]+[+][0-9]+$ ]] || { echo "Invalid release reference: $release_ref" >&2; exit 2; }
release_dir="${RELEASES_DIR:-releases}/$release_ref"
qa_dir="$release_dir/device_qa"
app_root="${APP_ROOT:-.}"
package_name="${ANDROID_PACKAGE_NAME:-}"
mkdir -p "$qa_dir"
[[ -n "$package_name" && "$package_name" != com.example.app ]] || { echo "Set ANDROID_PACKAGE_NAME in framework.env" >&2; exit 1; }
command -v adb >/dev/null && command -v flutter >/dev/null || { echo "adb and flutter are required" >&2; exit 1; }

device_id="${ANDROID_DEVICE_ID:-}"
if [[ -z "$device_id" ]]; then
  while IFS= read -r candidate; do
    [[ "$(adb -s "$candidate" shell getprop ro.kernel.qemu 2>/dev/null | tr -d '\r')" != 1 ]] && { device_id="$candidate"; break; }
  done < <(adb devices | awk 'NR > 1 && $2 == "device" {print $1}')
fi
if [[ -z "$device_id" ]]; then
  printf '{"status":"DEVICE_NOT_FOUND","release_ref":"%s"}\n' "$release_ref" >"$qa_dir/status.json"
  exit 10
fi

(cd "$app_root" && flutter build apk --debug)
adb -s "$device_id" shell pm clear "$package_name" >/dev/null || true
adb -s "$device_id" install -r "$app_root/build/app/outputs/flutter-apk/app-debug.apk" >/dev/null
set +e
(cd "$app_root" && flutter test "${INTEGRATION_TEST_DIR:-integration_test}" -d "$device_id" --reporter expanded) >"$qa_dir/integration_test.log" 2>&1
result=$?
set -e
adb -s "$device_id" logcat -d -v threadtime >"$qa_dir/logcat.txt" || true
if [[ $result -eq 0 ]]; then status=PASS; else status=FAIL; fi
printf '{"status":"%s","release_ref":"%s","device_id":"%s"}\n' "$status" "$release_ref" "$device_id" >"$qa_dir/status.json"
exit "$result"
