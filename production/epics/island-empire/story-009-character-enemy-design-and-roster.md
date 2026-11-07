# Story 009: Characters, Combat Units & Enemy Faction Roster

**Epic**: Island Empire Vertical Slice
**Status**: Complete
**Priority**: High

## Summary
Designs and implements the full roster of characters, player units, and hostile enemy factions using CCGS design skills (`design-system`, `asset-spec`, and `team-combat`), backed by PixelLab MCP-generated pixel art assets, Godot 4.7 unit classes, dynamic raid wave progression, and comprehensive unit test coverage.

## Acceptance Criteria
- [x] Author comprehensive Game Design Document `design/gdd/characters-and-enemies.md` defining stats, roles, counters, and formulas for player and enemy factions.
- [x] Register all units, stats, and sources in `design/registry/entities.yaml`.
- [x] Author Visual Asset Specifications in `design/assets/character-specs.md`.
- [x] Generate 5 custom pixel art character & enemy assets via PixelLab MCP:
  - `royal_knight.png` (Noble cavalry knight with lance on armored warhorse)
  - `corsair_raider.png` (Rogue pirate with eye patch and dual cutlasses)
  - `dread_captain.png` (Pirate warlord boss in tricorn hat with golden saber and pistol)
  - `clan_berserker.png` (Tribal barbarian with war paint swinging spiked club)
  - `clan_chieftain.png` (Beast skull helmet warlord boss with stone battleaxe)
- [x] Implement `RoyalKnight` in `src/units/knight.gd` with steed barding visual and high mobility.
- [x] Expand `MilitaryUnit` to support `corsair_raider`, `dread_captain`, `clan_berserker`, and `clan_chieftain` with automated billboard rendering and boss aura rings.
- [x] Update `EnemyCamp` in `src/ai/enemy_camp.gd` to stage Chieftain Gorgar as the guardian boss, and escalate amphibious raids up to Dread Captain Flint boss waves.
- [x] Author automated unit tests in `tests/unit/test_factions_and_units.gd` and execute via `tests/test_runner.gd` (17/17 tests passing).
