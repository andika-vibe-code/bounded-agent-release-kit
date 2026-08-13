#!/usr/bin/env bash
set -euo pipefail

# Uploads a built AAB through the Android Publisher API. It intentionally
# refuses production, requires an explicit service-account file, and leaves
# credentials outside Git.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
[[ -f framework.env ]] && source framework.env
[[ $# -eq 1 ]] || { echo "Usage: $0 vX.Y.Z+N" >&2; exit 2; }

release_ref="${1#releases/}"
release_ref="${release_ref%/}"
[[ "$release_ref" =~ ^v[0-9]+[.][0-9]+[.][0-9]+[+][0-9]+$ ]] || { echo "Invalid release reference: $release_ref" >&2; exit 2; }
release_dir="${RELEASES_DIR:-releases}/$release_ref"
aab_file="${PLAY_AAB_FILE:-$release_dir/build/app-release.aab}"
account_file="${PLAY_ACCOUNT_FILE:-secrets/play-account.json}"
package_name="${ANDROID_PACKAGE_NAME:-}"
track="${PLAY_TRACK:-internal}"

[[ "$track" != production ]] || { echo "Production uploads are intentionally unsupported." >&2; exit 2; }
[[ -f "$aab_file" ]] || { echo "Missing AAB: $aab_file" >&2; exit 1; }
[[ -f "$account_file" ]] || { echo "Missing service-account JSON: $account_file" >&2; exit 1; }
[[ -n "$package_name" && "$package_name" != com.example.app ]] || { echo "Set ANDROID_PACKAGE_NAME in framework.env" >&2; exit 1; }
command -v curl >/dev/null && command -v openssl >/dev/null && command -v python3 >/dev/null || { echo "curl, openssl, and python3 are required." >&2; exit 1; }

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/bounded-play-upload.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
private_key_file="$work_dir/private-key.pem"

service_email="$(python3 - "$account_file" "$private_key_file" <<'PY'
from pathlib import Path
import json
import sys

account_path, key_path = sys.argv[1:]
data = json.loads(Path(account_path).read_text())
for field in ("client_email", "private_key"):
    if not data.get(field):
        raise SystemExit(f"Service account is missing {field}")
Path(key_path).write_text(data["private_key"])
Path(key_path).chmod(0o600)
print(data["client_email"])
PY
)"
token_uri="$(python3 - "$account_file" <<'PY'
from pathlib import Path
import json
import sys
print(json.loads(Path(sys.argv[1]).read_text()).get("token_uri", "https://oauth2.googleapis.com/token"))
PY
)"

now="$(date +%s)"
unsigned_jwt="$(python3 - "$service_email" "$now" "$token_uri" <<'PY'
import base64
import json
import sys

email, now, token_uri = sys.argv[1], int(sys.argv[2]), sys.argv[3]
def encode(value):
    return base64.urlsafe_b64encode(json.dumps(value, separators=(",", ":")).encode()).decode().rstrip("=")
print(f"{encode({'alg': 'RS256', 'typ': 'JWT'})}.{encode({'iss': email, 'scope': 'https://www.googleapis.com/auth/androidpublisher', 'aud': token_uri, 'iat': now, 'exp': now + 3600})}")
PY
)"
signature="$(printf '%s' "$unsigned_jwt" | openssl dgst -sha256 -sign "$private_key_file" | openssl base64 -A | tr '+/' '-_' | tr -d '=')"
token_body="$work_dir/token.json"
token_code="$(curl -sS -o "$token_body" -w '%{http_code}' --request POST --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' --data-urlencode "assertion=$unsigned_jwt.$signature" "$token_uri")"
[[ "$token_code" =~ ^2 ]] || { echo "OAuth token request failed (HTTP $token_code)" >&2; exit 4; }
access_token="$(python3 - "$token_body" <<'PY'
from pathlib import Path
import json
import sys
token = json.loads(Path(sys.argv[1]).read_text()).get("access_token")
if not token:
    raise SystemExit("OAuth response did not include access_token")
print(token)
PY
)"

api_base="https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$package_name"
upload_base="https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/$package_name"
api_call() {
  local body_file="$1"
  shift
  local code
  code="$(curl -sS -o "$body_file" -w '%{http_code}' -H "Authorization: Bearer $access_token" "$@")"
  if [[ "$code" == 409 ]]; then
    echo "Google Play rejected the edit (HTTP 409: duplicate version code or conflicting edit)." >&2
    return 3
  fi
  [[ "$code" =~ ^2 ]] || { echo "Google Play request failed (HTTP $code): $(sed -n '1,3p' "$body_file")" >&2; return 4; }
}

edit_body="$work_dir/edit.json"
api_call "$edit_body" --request POST "$api_base/edits"
edit_id="$(python3 - "$edit_body" <<'PY'
from pathlib import Path
import json
import sys
value = json.loads(Path(sys.argv[1]).read_text()).get("id")
if not value:
    raise SystemExit("Play edit response did not include an id")
print(value)
PY
)"
bundle_body="$work_dir/bundle.json"
api_call "$bundle_body" --request POST -H 'Content-Type: application/octet-stream' --data-binary "@$aab_file" "$upload_base/edits/$edit_id/bundles?uploadType=media"
version_code="$(python3 - "$bundle_body" <<'PY'
from pathlib import Path
import json
import sys
codes = json.loads(Path(sys.argv[1]).read_text()).get("versionCodes") or []
if not codes:
    raise SystemExit("Play bundle response did not include versionCodes")
print(codes[0])
PY
)"
track_body="$work_dir/track.json"
python3 - "$track_body" "$version_code" "$track" <<'PY'
from pathlib import Path
import json
import sys
Path(sys.argv[1]).write_text(json.dumps({"track": sys.argv[3], "releases": [{"name": sys.argv[2], "versionCodes": [sys.argv[2]], "status": "completed"}]}))
PY
api_call "$work_dir/track-response.json" --request PUT -H 'Content-Type: application/json' --data-binary "@$track_body" "$api_base/edits/$edit_id/tracks/$track"
api_call "$work_dir/commit-response.json" --request POST "$api_base/edits/$edit_id:commit"

mkdir -p "$release_dir/play_upload"
python3 - "$release_dir/play_upload/status.json" "$package_name" "$track" "$version_code" "$aab_file" <<'PY'
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import sys
path, package_name, track, version_code, aab_file = sys.argv[1:]
Path(path).write_text(json.dumps({"status": "uploaded", "package_name": package_name, "track": track, "version_code": int(version_code), "aab_sha256": hashlib.sha256(Path(aab_file).read_bytes()).hexdigest(), "completed_at": datetime.now(timezone.utc).isoformat()}, indent=2) + "\n")
PY
echo "Uploaded $package_name versionCode=$version_code to $track"
