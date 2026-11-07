# Story 003: Building Placement & Construction System

> **Epic**: Island Empire MVP
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Last Updated**: 2026-11-07

## Context
**Brief**: `design/game-brief.md` — Item 3
**Engine**: Godot 4.7 | **Language**: GDScript

## Acceptance Criteria
- [ ] Building placement mode shows holographic 3D ghost preview under cursor/finger with green (valid) / red (obstructed) shaders.
- [ ] 6 core buildings supported: Town Center, House (+pop cap), Farm (food regen), Lumber Camp (wood drop-off), Barracks (unit training), Harbor (ships).
- [ ] Placement validates: on island land (or water edge for Harbor), within island bounds, not overlapping obstacles or other buildings.
- [ ] Placing starts a construction foundation requiring villager builders to construct or auto-builds over time with allocated wood/stone cost.
- [ ] Completed buildings increase population ceiling or unlock new production menus.

## Files
- `src/buildings/building_base.gd`
- `src/buildings/building_placement.gd`
- `src/buildings/building_data.gd`
