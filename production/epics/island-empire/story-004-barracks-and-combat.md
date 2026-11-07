# Story 004: Barracks, Unit Training & Squad Combat

> **Epic**: Island Empire MVP
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Last Updated**: 2026-11-07

## Context
**Brief**: `design/game-brief.md` — Item 4
**Engine**: Godot 4.7 | **Language**: GDScript

## Acceptance Criteria
- [ ] Barracks trains Spearmen (melee tank) and Archers (ranged attacker) when resources and population allow.
- [ ] Drag-select rectangle on screen allows multiselecting military units with clear floating selection rings.
- [ ] Right-click or smart-tap orders squad to move in formation or attack targeted hostile units.
- [ ] Melee combat deals timed strikes with floating combat damage text; Archers fire ballistic arrows with arc trajectories.
- [ ] Units display overhead health bars and play death / victory animations.

## Files
- `src/units/unit_base.gd`
- `src/units/spearman.gd`
- `src/units/archer.gd`
- `src/combat/projectile.gd`
- `src/combat/selection_manager.gd`
