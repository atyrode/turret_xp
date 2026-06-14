#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failed=0
core_picker="scripts/control/gui/core_picker_table.lua"
core_panel="scripts/control/gui/core_panel.lua"
styles="prototypes/styles.lua"

if grep -nE 'draw_(horizontal|vertical)_lines|draw_horizontal_line_after_headers' "$core_picker"; then
  echo "Core picker table must not use native table grid-line rendering." >&2
  failed=1
fi

if grep -nE 'type *= *"table"' "$core_picker"; then
  echo "Core picker table must render as header/body flows, not a native table element." >&2
  failed=1
fi

if grep -nE 'separator|add_separator_cell|inventory_core_table_separator' "$core_picker" "$styles"; then
  echo "Core picker table must not reintroduce separator widgets or styles." >&2
  failed=1
fi

if grep -nE '(level|hp|attack|range)_caption = rich_value' "$core_panel"; then
  echo "Core picker level/stat captions must stay plain, not rich-value green." >&2
  failed=1
fi

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "GUI contract checks passed."
