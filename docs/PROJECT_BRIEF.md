# Project Brief

`turret_xp` is a Factorio 2.0 mod that lets selected vanilla gun turrets become persistent veteran defenders.

The player installs a Veteran Core into a normal gun turret, lets that turret earn XP from combat, and then shapes the core through upgrades, specializations, sub-specializations, elemental material ranks, labels, and optional bound turret movement. Ordinary gun turrets remain stackable and disposable until the player chooses to install a core.

## Current Product Intent

- Make defensive infrastructure feel personal without turning every cheap turret into unique inventory metadata.
- Keep the vanilla gun turret GUI as the main interaction and attach Turret XP controls beside it.
- Let Veteran Cores carry identity: XP, levels, upgrades, elements, name, label settings, combat history, and relevant movement metadata.
- Make growth come from both combat and industrial commitment: combat grants XP/levels, while passive material feeding advances selected element ranks.
- Preserve Factorio's logistics feel: ammo inserters should still feed the turret, and material inserters should be able to feed selected element ranks without visible fake containers.
- Keep major build choices readable as distinct roles: long-range sniper, rapid machine gun, durable bulwark, close-range brawler, and elemental hybrids.

## Current Scope

- Runtime scope is vanilla `gun-turret` only.
- Veteran Cores are non-stackable tagged items that can move between turrets.
- Bound veteran turrets are optional tagged placeable items for quick moves of one turret/core pair.
- Combat XP uses damage contribution and kill credit, with target-aware and space-platform-aware XP weighting.
- Evolution currently has six level-gated sections: core upgrades, specialization, first element, augments, sub-specialization, and second element/combo.
- Specialization and sub-specialization stat changes use hidden prototype-backed turret variants because Factorio does not expose equivalent per-entity runtime stat mutation. Prototype-bound native stat identity is intentionally limited to those role bodies and their bound preview variants.
- Shield and Resistance are scripted rather than prototype-backed to avoid reintroducing Range/Max HP variant axes.
- Hidden feeder automation remains the accepted material-input model for the current line: keep and harden the invisible turret-tile input unless playtesting proves the model is too confusing.
- Fire and Toxic delayed damage are tracked so scripted damage-over-time still contributes to XP, kill credit, and lifesteal.
- Space-platform turrets can select exact Veteran Cores from the platform hub inventory.
- CI and local validation include strict Lua tooling, packaging, and Factorio headless regression tests where Factorio binaries/credentials are available.

## Current Non-Goals

- Do not support laser, flamethrower, artillery, electric, or broad modded turret families until vanilla gun-turret progression is stable.
- Do not replace the attached vanilla turret panel as an incidental refactor. The approved next major GUI direction is a custom Factorio-native Turret XP interface, but it should arrive as a dedicated GUI pass with focused helpers, dependency justification, visual validation, and no bundled gameplay balance changes.
- Do not add new prototype-backed stat axes or raise prototype-generating caps without explicit product approval. Repeatable Range/Max HP prototype axes, quality-backed chassis rewrites, and range-band rewrites are not current or future default scope.
- Do not add new progression systems such as new branches, elements, mastery loops, or prototype-bound stat axes during the current hardening pass without a separate approved issue.
- Do not turn `turret_xp_test` into a public remote interface; it is private headless-test surface only.
- Do not duplicate release history in active planning docs. `changelog.txt` is the canonical release-history file and must stay compatible with the Factorio Mod Portal changelog format.

## Release History

Version-specific changes belong in `changelog.txt`. The package includes that file at the mod root for Factorio and Mod Portal use. Public website, release-note, and Mod Portal automation reuses it rather than maintaining separate release diaries in active docs.

Historical planning context is kept by git history, not by active docs. If an old plan contains a still-useful decision, move that decision into the relevant current document instead of keeping the old plan around.

## Open Product Boundaries

- Final portal presentation can still improve: thumbnail/key art, summary, tags, and public copy should stay sober, Factorio-native, and specific to Veteran Core turret progression.
- Destroyed turrets currently lose the installed core. A future design may keep that, drop a damaged core, or add a recovery chance.
- Hidden turret-tile material input should keep being playtested with practical inserter layouts. Near-term work should improve diagnostics/readability around the current invisible model before considering replacement.
- Long-term progression may add deeper archetype branches, material gates, combos, mastery sinks, or support behavior only after the current Fire/Electric/Explosive/Toxic loop is readable and balanced.
- XP may eventually include more than damage and kill credit, but any extra source should avoid passive farming and should be clear to players.
