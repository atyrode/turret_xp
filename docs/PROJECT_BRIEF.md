# Project Brief

`turret_xp` is a Factorio 2.0 mod that adds progression to vanilla gun turrets.

The first playable release should make the progression visible without changing combat balance yet: each gun turret earns XP from combat, gains levels, and displays its current progress and combat stats inside or alongside the vanilla turret GUI.

## V0.1.0 Scope

- Track XP, level, kills, lifetime damage, and total XP per vanilla `gun-turret`.
- Award XP from damage dealt by gun turrets and a small kill bonus.
- Extend the vanilla gun turret GUI with a Turret XP panel.
- Show HP, attack speed, range, loaded ammo, estimated ammo damage, kills, damage, total XP, current level, and XP to next level.
- Package and publish as version `0.1.0` so the mod can be installed from the Factorio Mod Portal.

## Non-Goals For V0.1.0

- Do not apply level bonuses to combat stats yet.
- Do not support laser, flamethrower, artillery, or modded turret prototypes yet.
- Do not persist mined turret XP through item pickup yet.
- Do not add custom art or new item prototypes yet.

## Open Product Questions

- Which stat bonuses should levels eventually grant: damage, fire rate, range, health, resistances, ammo efficiency, or a mixed tree?
- Should progression be per physical turret, per force, or transferable through picked-up turret items?
- Should XP be awarded by damage dealt, kills, waves survived, ammo consumed, or a weighted combination?
