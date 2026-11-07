# Story 002: Resource Gathering & Villager Economy

> **Epic**: Island Empire MVP
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Last Updated**: 2026-11-07

## Context
**Brief**: `design/game-brief.md` — Item 2
**Engine**: Godot 4.7 | **Language**: GDScript

## Acceptance Criteria
- [ ] Resource nodes spawn on the island: Trees (Wood), Rock Boulders (Stone), Berry Bushes (Food), and Gold Veins (Gold).
- [ ] Villagers can be selected via click/tap and commanded to harvest specific resource nodes.
- [ ] Villager gathers resource up to carry capacity (e.g. 10 units), then paths to nearest Town Center or Storehouse to deposit.
- [ ] Global resource bank increases upon deposit and broadcasts updates to UI listeners.
- [ ] When a resource node is depleted, villagers automatically search for the nearest matching node or transition to Idle.

## Files
- `src/economy/resource_manager.gd`
- `src/economy/resource_node.gd`
- `src/units/villager.gd`
