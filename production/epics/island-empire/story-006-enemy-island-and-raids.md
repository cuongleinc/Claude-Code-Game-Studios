# Story 006: Enemy Island Camp & Amphibious Raids

> **Epic**: Island Empire MVP
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Last Updated**: 2026-11-07

## Context
**Brief**: `design/game-brief.md` — Item 6
**Engine**: Godot 4.7 | **Language**: GDScript

## Acceptance Criteria
- [ ] A second distinct island ("Skull Island" / Rival Faction) spawns across the sea channel.
- [ ] Enemy island has defensive watchtowers, a chieftain totem shrine, and patrolling barbarian defenders.
- [ ] Periodic timer triggers enemy landing parties sailing to player island to attack player farms and villagers.
- [ ] Defeating the chieftain totem claims Island 2 and unlocks victorious conquer banners.

## Files
- `src/ai/enemy_controller.gd`
- `src/ai/raid_spawner.gd`
- `src/buildings/totem_shrine.gd`
