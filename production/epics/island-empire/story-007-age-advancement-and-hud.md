# Story 007: Age Advancement, RTS HUD & Game Loop

> **Epic**: Island Empire MVP
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Last Updated**: 2026-11-07

## Context
**Brief**: `design/game-brief.md` — Item 7
**Engine**: Godot 4.7 | **Language**: GDScript

## Acceptance Criteria
- [ ] Top HUD displays real-time resource meters (Wood, Stone, Food, Gold), Population fraction (Current/Max), and current Age emblem.
- [ ] Speed controls on HUD: Pause (0x), Normal (1x), Fast (2x).
- [ ] Build menu drawer at screen bottom allows selecting buildings with resource cost checks and tooltips.
- [ ] Age Advancement button activates when resource threshold is met (e.g. 500 Food, 300 Gold, Barracks built), upgrading settlement from Stone Age to Bronze Age.
- [ ] Victory banner upon conquering Island 2; Defeat banner if player Town Center is destroyed.
- [ ] Save/Load system serializes island layout, unit positions, resources, and Age state to `user://savegame.json`.

## Files
- `src/ui/rts_hud.gd`
- `src/ui/rts_hud.tscn`
- `src/core/game_manager.gd`
- `src/core/save_system.gd`
