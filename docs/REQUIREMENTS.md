# Requirements

## Functional

- The mod must load in Factorio 2.0 with `base >= 2.0.0` and `flib >= 0.16.4`.
- Opening a vanilla gun turret must show a Turret XP panel attached to the vanilla turret GUI when possible.
- Ordinary gun turrets must remain stackable and must not gain progression until a Veteran Core is installed.
- Each installed Veteran Core must have independent tracked progression state.
- A Veteran Core must be extractable and reinstallable into another gun turret while retaining XP, upgrades, element projects, custom name, and label preference.
- On space platforms, the attached turret panel must allow selecting a specific Veteran Core from the platform hub inventory and sending an installed core back to the hub when there is room.
- Gun turret damage against non-friendly entities must add lifetime damage and damage-derived XP only when the attacking turret has an installed core.
- Gun turret combat on space-platform surfaces must add only 10% of normal damage-derived and kill-credit-derived XP while preserving raw displayed damage and kill-credit totals.
- Enemy deaths must add proportional kill-credit XP to contributing installed cores, even when another source lands the final hit.
- Gun turret final hits must add a killing-blow count to the installed core.
- Mining a turret with an installed core must return the normal turret item through vanilla behavior and return or spill the core separately.
- Installing a Veteran Core must create a real hidden feeder inventory entity on the turret tile.
- Material projects and element fuel must consume matching resources from the hidden feeder inventory, not from the player inventory.
- Inserter-fed ammo that enters the hidden feeder must be forwarded into the turret ammo inventory.
- Unsupported non-ammo items that are not currently needed for element progression must not remain trapped in the hidden feeder.
- Extracting or mining a core must destroy the feeder and spill leftover feeder contents.
- The core profile must optionally render a floating label above its current turret body in `name (lvl N)` format.
- Runtime-global mod settings must allow tuning damage XP, kill-credit XP, base level XP, and level XP growth.
- XP overflow must advance levels and carry remaining XP into the next level.
- Evolution points must be derived from turret level and spent allocations.
- Clicking an allocatable core upgrade or augment must allocate one rank to the opened turret and refresh the panel.
- Range augment ranks must change real turret attack range, not only the displayed range value.
- Clicking an element option must start a material project when the corresponding level gate is unlocked.
- Feeding required items into the turret's hidden material input must advance the active material project and unlock the element when requirements are complete.
- After an element is unlocked, feeding that element's resource must fill a bounded burner fuel buffer used by element combat effects.
- Inserter-fed element resources must fill the post-unlock fuel buffer up to capacity, and the hidden input must close at that cap instead of storing ghost excess.
- Dev buttons must be hidden by default and toggleable with `/turret-xp-dev` for local playtesting.
- The GUI must refresh while the turret GUI remains open.
- Selecting a gun turret and running `/turret-xp` must open the same panel as a fallback.
- The packaged zip must include `info.json`, Lua files, locale, docs, README, and changelog.

## Display

- Show current level and XP progress to the next level.
- Show whether a Veteran Core is installed and provide install/extract controls.
- On space-platform turrets, show platform hub Veteran Core options when cores are available there.
- Show current HP and prototype max HP.
- Show shooting speed in shots per second, including force gun-speed bonuses.
- Show turret attack range in tiles, including quality range multiplier when relevant.
- Show loaded ammo and count.
- Show estimated loaded-ammo damage per shot and estimated DPS when they can be derived from prototype data.
- Show kills, lifetime damage, and evolution points.
- Show a five-section Evolution list: core upgrades, first element, specialization, powerful augments, and second element/combo.
- Show clear delimiters between choices inside the unlocked Evolution sections.
- Show locked section level gates before the turret reaches them.
- Show material requirements and progress for the active element project, plus burner state, burn progress, and stored fuel for unlocked elements.
- Show a core naming field and a floating-label toggle when a core is installed.
- Preserve Evolution list context after point allocation so the panel does not jump back to the top.
- Clearly state that V0.5.x evolution effects are early draft effects, not final balance.

## Operational

- `.env` must remain ignored and must not be committed.
- `scripts/check.sh` must validate JSON and Lua syntax when `luac` is available.
- `scripts/package.sh` must create `dist/turret_xp_<info.json version>.zip`.
- `scripts/release.sh` must publish/update the matching GitHub release.
- `scripts/publish-portal.sh` must publish/update the matching Factorio Mod Portal release.
