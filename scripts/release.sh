#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

scripts/release-preflight.sh "GitHub release"

python_bin="${PYTHON:-python3}"
version="$("$python_bin" -c 'import json; print(json.load(open("info.json"))["version"])')"
tag="v${version}"
notes_path="dist/release-notes-${version}.md"

scripts/generate-public-assets.py --check
scripts/generate-public-assets.py --release-notes "$notes_path"

head_sha="$(git rev-parse HEAD)"
remote_tag="$(
  {
    git ls-remote --tags origin "${tag}^{}"
    git ls-remote --tags origin "$tag"
  } | awk 'NR == 1 {print $1}'
)"
if [ -n "$remote_tag" ] && [ "$remote_tag" != "$head_sha" ]; then
  echo "Remote tag ${tag} points to ${remote_tag}, not current HEAD ${head_sha}." >&2
  echo "Refusing to move an existing release tag." >&2
  exit 1
fi

if ! git rev-parse --verify --quiet "$tag" >/dev/null; then
  git tag -s "$tag" -m "Turret XP ${version}"
fi

local_tag="$(git rev-parse "${tag}^{commit}")"
if [ "$local_tag" != "$head_sha" ]; then
  echo "Local tag ${tag} points to ${local_tag}, not current HEAD ${head_sha}." >&2
  echo "Refusing to move an existing release tag." >&2
  exit 1
fi

if [ -z "$remote_tag" ]; then
  git push origin "$tag"
fi

if gh release view "$tag" >/dev/null 2>&1; then
  gh release edit "$tag" --target "$head_sha" --title "Turret XP ${version}" --notes-file "$notes_path"
else
  gh release create "$tag" --target "$head_sha" --title "Turret XP ${version}" --notes-file "$notes_path"
fi

gh release view "$tag" --web=false
echo "The Release workflow now builds, tests, attaches the package, and publishes it to the Factorio Mod Portal."
