# Requirements

## Functional

- The mod must load in Factorio 2.0 with `base >= 2.0.0` and `flib >= 0.16.4`.
- The mod may optionally integrate with `bullet-trails >= 0.7.1` when installed, but must still load without it.
- Opening a vanilla gun turret must show a Turret XP panel attached to the vanilla turret GUI when possible.
- Ordinary gun turrets must remain stackable and must not gain progression until a Veteran Core is installed.
- Each installed Veteran Core must have independent tracked progression state.
- A Veteran Core must be extractable and reinstallable into another gun turret while retaining XP, upgrades, element ranks/material progress, custom name, and label preference.
- An installed Veteran Core must be able to opt into a bound quick-move mode where mining returns one tagged placeable turret item that restores the turret and core together when placed.
- Unbinding must return the turret to the default separate turret item plus Veteran Core movement behavior.
- On space platforms, the attached turret panel must allow selecting a specific Veteran Core from the platform hub inventory and sending an installed core back to the hub when there is room.
- Gun turret damage against non-friendly entities must add lifetime damage and damage-derived XP only when the attacking turret has an installed core.
- Gun turret combat on space-platform surfaces must add reduced damage-derived and kill-credit-derived XP while preserving raw displayed damage and kill-credit totals.
- Asteroids and asteroid chunks must grant reduced XP compared with normal enemies, including when fought on space platforms.
- Kill-credit XP should account for target type and approximate target durability so small targets, large enemies, worms, and spawners do not all pay the same XP.
- Enemy deaths must add proportional kill-credit XP to contributing installed cores, even when another source lands the final hit.
- Gun turret final hits must add a killing-blow count to the installed core.
- Mining a turret with an installed unbound core must return the normal turret item through vanilla behavior and return or spill the core separately.
- Mining a bound veteran turret must not duplicate the normal turret/core outputs; it must return one bound veteran turret item when possible and spill that tagged bound item if inventory space is unavailable.
- Mining a bound veteran turret must not fall back to a separate Veteran Core result or lose the core profile when the mining buffer is full.
- Placing a bound veteran turret must restore the saved ammo snapshot without duplicating or deleting ammo inserted by placement helper mods; matching placement-time ammo should satisfy the saved snapshot, and only excess or incompatible placement-time ammo should be returned or spilled.
- Newly created bound veteran turret stacks with specialization or Range ranks should use hidden preview item variants so the cursor placement range visualization reflects the turret that will be restored.
- The bound veteran turret item must not be treated as an equivalent replacement item for ordinary vanilla gun-turret ghosts. Destroying a regular gun turret with no installed core must create a normal gun-turret replacement ghost.
- Installing a Veteran Core must create a real hidden feeder inventory entity on the turret tile.
- Element rank material progress must consume matching resources from the hidden feeder inventory, not from the player inventory.
- Inserter-fed ammo that enters the hidden feeder must be forwarded into the turret ammo inventory.
- The runtime must prevent normal unsupported non-ammo insertion by managing nearby inserter targets and temporary filters while element input is needed.
- If an unsupported non-ammo item still enters the hidden feeder through an edge case, normal routing must clear the invalid stack so element progress can continue instead of staying blocked by hidden junk.
- Extracting or mining a core must destroy the feeder and spill leftover feeder contents.
- The core profile must optionally render a floating label above its current turret body in `name (lvl N)` format.
- The Evolution header must expose one clear reset action that clears all Evolution choices while preserving core XP/history. Selected elements, specialization, and sub-specialization must also expose clear section-level `Change` actions for focused local edits.
- Floating-label color controls must only appear while the `Show` label checkbox is enabled.
- Preset label-color cycling must keep preset captions; `Custom` should appear only after RGB slider edits.
- Runtime-global mod settings must allow tuning damage XP, kill-credit XP, base level XP, and level XP growth.
- XP overflow must advance levels and carry remaining XP into the next level.
- Evolution points must be derived from turret level and spent allocations.
- Clicking an allocatable core upgrade or augment must allocate one rank to the opened turret and refresh the panel.
- Range augment ranks must change real turret attack range, not only the displayed range value.
- Max HP augment ranks must change real turret max health through hidden prototype-backed variants and must remain capped to avoid unbounded prototype growth.
- Resistance core upgrade ranks must reduce non-lethal incoming damage through scripted mitigation without adding more hidden turret variants.
- Ammo Recovery core upgrade ranks must regenerate the current or remembered ammo item over time, but must not create ammo for a turret that has never held ammo.
- Clicking an element option must assign rank 1 for free when the corresponding level gate is unlocked.
- Unlocked elements must always show their current rank, technical effect, next-rank material, and passive progress bar; there is no separate upgrade-start click.
- Feeding required items into the turret's hidden material input must advance the selected element's passive material progress and increase the element rank when requirements are complete.
- Passive material progress must expose enough bounded hidden-input slots for normal and bulk inserters to feed between routing ticks without hitting `Target full` after every single item.
- After an element is unlocked, feeding that element's resource must be accepted whenever the element has a next-rank requirement.
- Mixed-element turrets must request and accept resources for every selected element that needs progress, and managed inserters should expose all currently needed resources in available filter slots while feeding progression resources.
- Dev buttons must be hidden by default and toggleable with `/turret-xp-dev` for local playtesting.
- The GUI must refresh while the turret GUI remains open.
- Selecting a gun turret and running `/turret-xp` must open the same panel as a fallback.
- The packaged zip must include `info.json`, Lua entrypoints, runtime/data prototype module files, locale, docs, README, changelog, and a root `thumbnail.png` when that file exists.
- Hidden specialization, Range, and Max HP turret variants must inherit late gun-turret prototype edits from other mods before adding Turret XP-specific stat changes.

## Display

- Show current level and XP progress to the next level.
- Show whether a Veteran Core is installed and provide install/extract controls.
- Show Bind/Unbind controls for installed cores.
- On space-platform turrets, show platform hub Veteran Core options when cores are available there.
- Show current HP and prototype max HP.
- Show Max HP augment and Ammo Recovery rows in the active custom stat summary when ranked.
- Show shooting speed in shots per second, including force gun-speed bonuses.
- Show turret attack range in tiles, including quality range multiplier when relevant.
- Show loaded ammo and count.
- Show estimated loaded-ammo damage per shot and estimated DPS when they can be derived from prototype data.
- Show kills, lifetime damage, and evolution points.
- Show a six-section Evolution column to the right of the core, XP, dev, and scrollable stats column: core upgrades, specialization, first element, powerful augments, sub-specialization, and second element/combo.
- Keep Core points, Augment points, and current Specialization summary in a static Evolution header above the scrollable section body instead of repeating those summaries inside sections. Format the header as `Core: value`, `Aug: value`, and `Spec: value` with white labels and colored values.
- Show clear section headers, right-side point/status text, and delimiters between choices inside the unlocked Evolution sections.
- Show technical element effect details before an element is selected, including proc chance, effect amount, damage type, resource, and combo preview when relevant.
- Format unselected element choices as readable card-like rows with separate title, description, effect, cost, and combo preview lines rather than a single dense text block.
- Show locked section level gates before the turret reaches them.
- Show material requirements and progress for every unlocked element's next passive rank, plus the current rank and technical effect.
- Show duplicate pure-element builds as one active element stat row plus their combo identity, not as duplicate stat summary lines.
- Always show baseline Crit Chance and Crit Damage in the stats summary when a core is installed, directly under Damage Dealt.
- Show active Resistance in the stats summary only after at least one Resistance rank is allocated.
- Apply and show specialization and sub-specialization multipliers, including Sniper Deadeye/Overwatch, Machine Gun Shredder/Sustained Fire, Bulwark Bastion/Guardian, and Brawler Executioner/Vampire.
- Reserve stats-scrollbar space so scrollable stat values do not render underneath the scrollbar.
- Color numeric fragments only in stat, upgrade, augment, specialization, sub-specialization, element, and material-count values. Units and descriptive text must remain neutral, and elemental damage amounts should color the number with the corresponding element color.
- Show a core naming field and a `Show` floating-label checkbox when a core is installed; show preset/RGB color controls only when the floating label is enabled, with the `Level` checkbox under the RGB picker.
- Custom RGB floating-label colors should keep the Factorio-style display-panel background and sizing, accepting palette quantization if arbitrary runtime display-panel text color is unavailable.
- Preserve Evolution list context after point allocation so the panel does not jump back to the top, and prevent GUI refreshes from resizing the attached panel in ways that move the vanilla turret GUI.
- Keep the attached two-column panel narrow enough for normal play, and ensure Evolution content wraps or shrinks inside the scroll pane instead of rendering under the scrollbar.
- Derive Evolution section, row, and text widths from one right-column viewport model so fixed controls and labels reserve scrollbar space consistently.
- Clearly state that V0.9.x evolution effects are early draft effects, not final balance.
- Electric visual feedback must expire automatically and must not leave beam or arc entities on the map after combat.
- Critical hits, double shots, bounce, and elemental procs should have readable visual feedback when possible, preferring optional Bullet Trails entities and vanilla visual prototypes with safe fallbacks.
- Fire and Toxic damage-over-time ticks must count as turret damage for XP, kill credit contribution, and lifesteal.

## Operational

- `.env` must remain ignored and must not be committed.
- `scripts/check.sh` must validate JSON and Lua syntax when `luac` is available.
- `scripts/package.sh` must create `dist/turret_xp_<info.json version>.zip`.
- `scripts/test-headless.sh` must run a controlled Factorio headless regression suite against the packaged mod before publishing.
- `scripts/release.sh` must publish/update the matching GitHub release.
- `scripts/publish-portal.sh` must publish/update the matching Factorio Mod Portal release and run the headless regression suite first unless explicitly bypassed with `SKIP_HEADLESS_TESTS=1`.
