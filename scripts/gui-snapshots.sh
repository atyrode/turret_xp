#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python_bin="${PYTHON:-python3}"
command="${1:-help}"
snapshot_name="${2:-current}"

default_mods_dir() {
  if [ "$(uname -s)" = "Darwin" ]; then
    printf '%s\n' "$HOME/Library/Application Support/factorio/mods"
    return
  fi
  printf '%s\n' "$HOME/.factorio/mods"
}

default_script_output_dir() {
  if [ "$(uname -s)" = "Darwin" ]; then
    printf '%s\n' "$HOME/Library/Application Support/factorio/script-output"
    return
  fi
  printf '%s\n' "$HOME/.factorio/script-output"
}

usage() {
  cat <<'EOF'
Usage:
  scripts/gui-snapshots.sh install
  scripts/gui-snapshots.sh collect [name]
  scripts/gui-snapshots.sh status

install
  Packages turret_xp, copies the GUI snapshot companion mod into the Factorio
  mods folder, and enables turret_xp_gui_snapshots in mod-list.json.

collect [name]
  Copies the latest screenshots from Factorio script-output into full/ and
  writes cropped Turret XP-only review images into ui/. Defaults to
  tests/gui-snapshots/current.

Environment:
  FACTORIO_MODS_DIR            Override the Factorio mods directory.
  FACTORIO_SCRIPT_OUTPUT_DIR   Override the Factorio script-output directory.
EOF
}

companion_version() {
  "$python_bin" -c 'import json; print(json.load(open("tests/gui-snapshots/turret_xp_gui_snapshots/info.json"))["version"])'
}

install_snapshotter() {
  local mods_dir="${FACTORIO_MODS_DIR:-$(default_mods_dir)}"
  local package_path
  local version
  local destination
  package_path="$(scripts/package.sh | tail -n 1)"
  version="$(companion_version)"
  destination="$mods_dir/turret_xp_gui_snapshots_$version"

  mkdir -p "$mods_dir"
  cp "$package_path" "$mods_dir/"
  rm -rf "$destination"
  cp -R "tests/gui-snapshots/turret_xp_gui_snapshots" "$destination"

  "$python_bin" - "$mods_dir/mod-list.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
enabled = {"base", "flib", "turret_xp", "turret_xp_gui_snapshots"}
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

  echo "Installed turret_xp and turret_xp_gui_snapshots into the Factorio mods folder."
  echo "Start Factorio, load a development save, then run: /turret-xp-snapshots"
}

collect_snapshots() {
  local script_output="${FACTORIO_SCRIPT_OUTPUT_DIR:-$(default_script_output_dir)}"
  local source_dir="$script_output/turret_xp/gui-snapshots/latest"
  local destination="tests/gui-snapshots/$snapshot_name"
  local full_destination="$destination/full"
  local ui_destination="$destination/ui"
  local png_files=()

  if [ ! -d "$source_dir" ]; then
    echo "Missing snapshot output directory: $source_dir" >&2
    echo "Run /turret-xp-snapshots in the graphical Factorio client first." >&2
    exit 2
  fi

  while IFS= read -r file; do
    png_files+=("$file")
  done < <(find "$source_dir" -maxdepth 1 -type f -name '*.png' | sort)

  if [ "${#png_files[@]}" -eq 0 ]; then
    echo "No PNG screenshots found in: $source_dir" >&2
    exit 2
  fi

  mkdir -p "$full_destination" "$ui_destination"
  find "$destination" -maxdepth 1 -type f \( -name '*.png' -o -name 'manifest.json' -o -name 'index.md' \) -delete
  find "$full_destination" -maxdepth 1 -type f -name '*.png' -delete
  find "$ui_destination" -maxdepth 1 -type f -name '*.png' -delete
  cp "${png_files[@]}" "$full_destination/"
  if [ -f "$source_dir/manifest.json" ]; then
    cp "$source_dir/manifest.json" "$destination/"
  fi

  "$python_bin" scripts/crop-gui-snapshots.py \
    --manifest "$destination/manifest.json" \
    --output "$ui_destination" \
    "$full_destination"/*.png

  {
    echo "# Turret XP GUI Snapshots"
    echo
    echo "Generated from the latest graphical-client snapshot run."
    echo
    echo 'The `ui/` images are cropped from the recorded Turret XP frame bounds. The `full/` images preserve the complete graphical-client screenshot for context.'
    echo
    for image in "$ui_destination"/*.png; do
      local base
      base="$(basename "$image")"
      echo "## ${base%.png}"
      echo
      echo "![${base%.png}](./ui/$base)"
      echo
      echo "[Full screenshot](./full/$base)"
      echo
    done
  } >"$destination/index.md"

  echo "Copied ${#png_files[@]} full screenshot(s) and cropped UI review image(s) into $destination"
}

status_snapshots() {
  local script_output="${FACTORIO_SCRIPT_OUTPUT_DIR:-$(default_script_output_dir)}"
  local source_dir="$script_output/turret_xp/gui-snapshots/latest"
  echo "Source: $source_dir"
  if [ -d "$source_dir" ]; then
    find "$source_dir" -maxdepth 1 -type f | sort
  else
    echo "No source directory yet."
  fi
  echo
  echo "Repo snapshots:"
  find tests/gui-snapshots -maxdepth 3 -type f \( -name '*.png' -o -name 'manifest.json' -o -name 'index.md' \) | sort
}

case "$command" in
  install)
    install_snapshotter
    ;;
  collect)
    collect_snapshots
    ;;
  status)
    status_snapshots
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
