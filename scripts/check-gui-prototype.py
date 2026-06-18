#!/usr/bin/env python3
"""Lightweight structural checks for the browser GUI prototype."""

from __future__ import annotations

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]


REQUIRED_FILES = [
    "tools/gui-prototype/index.html",
    "tools/gui-prototype/styles.css",
    "tools/gui-prototype/fixtures.js",
    "tools/gui-prototype/app.js",
    "tools/gui-prototype/README.md",
    "docs/gui-spec/README.md",
    "docs/gui-spec/browser-prototype.md",
    "docs/gui-spec/core-picker.md",
    "docs/gui-spec/workbench.md",
    "docs/gui-spec/build-plan.md",
    "docs/gui-spec/stat-inspector.md",
    "docs/gui-spec/factorio-style-notes.md",
    "docs/gui-spec/browser-builder-roadmap.md",
]

REQUIRED_FIXTURES = [
    "empty_no_cores",
    "empty_inventory_cores",
    "empty_platform_cores",
    "installed_level_100_unspent",
    "build_plan_unspent",
    "copied_target_conflict",
]

REQUIRED_ANCHORS = [
    "turret_xp_core_picker",
    "turret_xp_core_picker_header",
    "turret_xp_core_picker_source",
    "turret_xp_core_picker_filter_sort",
    "turret_xp_core_picker_table",
    "turret_xp_core_picker_empty_state",
    "turret_xp_installed_workbench",
    "turret_xp_workbench_header",
    "turret_xp_core_slot",
    "turret_xp_xp_bar",
    "turret_xp_mode_bar",
    "turret_xp_build_plan_toggle",
    "turret_xp_follow_build_toggle",
    "turret_xp_progression_editor",
    "turret_xp_progression_core_upgrades",
    "turret_xp_progression_role_path",
    "turret_xp_progression_elements",
    "turret_xp_progression_augments",
    "turret_xp_stat_inspector",
    "turret_xp_stat_damage",
    "turret_xp_stat_dps",
    "turret_xp_stat_range",
    "turret_xp_stat_hp",
    "turret_xp_stat_resistance",
    "turret_xp_stat_crit",
    "turret_xp_stat_ammo",
    "turret_xp_build_plan_delta",
    "turret_xp_build_conflict",
    "turret_xp_detail_drawer",
    "turret_xp_core_details_drawer",
]

FORBIDDEN_PAYLOADS = [
    "webcdn.factorio.com/assets/img",
    "data:image",
    "border-image:url",
    ".panel-hole-inner",
]


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        raise AssertionError(f"missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def assert_contains(blob: str, token: str, context: str) -> None:
    if token not in blob:
        raise AssertionError(f"{context} does not contain required token: {token}")


def main() -> int:
    for relative in REQUIRED_FILES:
        read(relative)

    prototype_blob = "\n".join(
        read(relative)
        for relative in [
            "tools/gui-prototype/index.html",
            "tools/gui-prototype/fixtures.js",
            "tools/gui-prototype/app.js",
            "tools/gui-prototype/styles.css",
        ]
    )

    docs_blob = "\n".join(
        read(relative)
        for relative in [
            "docs/gui-spec/README.md",
            "docs/gui-spec/browser-prototype.md",
            "docs/gui-spec/core-picker.md",
            "docs/gui-spec/workbench.md",
            "docs/gui-spec/build-plan.md",
            "docs/gui-spec/stat-inspector.md",
            "docs/gui-spec/factorio-style-notes.md",
            "docs/gui-spec/browser-builder-roadmap.md",
        ]
    )

    for fixture in REQUIRED_FIXTURES:
        assert_contains(prototype_blob, fixture, "prototype")
        assert_contains(docs_blob, fixture, "GUI spec docs")

    for anchor in REQUIRED_ANCHORS:
        assert_contains(prototype_blob, anchor, "prototype")
        assert_contains(docs_blob, anchor, "GUI spec docs")

    for forbidden in FORBIDDEN_PAYLOADS:
        if forbidden in prototype_blob:
            raise AssertionError(f"prototype appears to vendor forbidden Factorio payload: {forbidden}")

    check_sh = read("scripts/check.sh")
    assert_contains(check_sh, "scripts/check-gui-prototype.sh", "scripts/check.sh")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"GUI prototype check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
