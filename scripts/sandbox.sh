#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python_bin="${PYTHON:-python3}"
command="${1:-help}"

default_mods_dir() {
  if [ "$(uname -s)" = "Darwin" ]; then
    printf '%s\n' "$HOME/Library/Application Support/factorio/mods"
    return
  fi
  printf '%s\n' "$HOME/.factorio/mods"
}

usage() {
  cat <<'EOF'
Usage:
  scripts/sandbox.sh install
  scripts/sandbox.sh status

install
  Packages turret_xp, copies the manual sandbox companion mod into the
  Factorio mods folder, and enables turret_xp_sandbox in mod-list.json.

Environment:
  FACTORIO_MODS_DIR  Override the Factorio mods directory.
EOF
}

companion_version() {
  "$python_bin" -c 'import json; print(json.load(open("tests/manual-sandbox/turret_xp_sandbox/info.json"))["version"])'
}

install_sandbox() {
  local mods_dir="${FACTORIO_MODS_DIR:-$(default_mods_dir)}"
  local package_path
  local version
  local destination
  package_path="$(scripts/package.sh | tail -n 1)"
  version="$(companion_version)"
  destination="$mods_dir/turret_xp_sandbox_$version"

  mkdir -p "$mods_dir"
  cp "$package_path" "$mods_dir/"
  rm -rf "$destination"
  cp -R "tests/manual-sandbox/turret_xp_sandbox" "$destination"

  "$python_bin" - "$mods_dir/mod-list.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
enabled = {"base", "flib", "turret_xp", "turret_xp_sandbox"}
if path.exists():
    data = json.loads(path.read_text())
else:
    data = {"mods": [{"name": "base", "enabled": True}]}

mods = {entry.get("name"): dict(entry) for entry in data.get("mods", []) if entry.get("name")}
for name in enabled:
    mods.setdefault(name, {"name": name})["enabled"] = True
data["mods"] = [mods[name] for name in sorted(mods)]
path.write_text(json.dumps(data, indent=2) + "\n")
PY

  if ! find "$mods_dir" -maxdepth 1 -type f -name 'flib_*.zip' | grep -q .; then
    echo "Warning: flib_*.zip was not found in the Factorio mods directory." >&2
    echo "Install flib from the Mod Portal before starting Factorio." >&2
  fi

  echo "Installed turret_xp and turret_xp_sandbox into the Factorio mods folder."
  echo "Start Factorio, load a disposable development save, then run: /turret-xp-sandbox build"
}

status_sandbox() {
  local mods_dir="${FACTORIO_MODS_DIR:-$(default_mods_dir)}"
  echo "Mods directory: $mods_dir"
  if [ -d "$mods_dir" ]; then
    find "$mods_dir" -maxdepth 1 \( -name 'turret_xp_*.zip' -o -name 'turret_xp_sandbox_*' -o -name 'flib_*.zip' \) | sort
  else
    echo "No mods directory yet."
  fi
}

case "$command" in
  install)
    install_sandbox
    ;;
  status)
    status_sandbox
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
