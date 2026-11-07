# QA Playtest & Verification Evidence: Island Empire MVP

> **Date**: 2026-11-07
> **Engine**: Godot 4.7.2 (Forward Mobile / Metal 4.0 on Apple M4)
> **Platform**: macOS / Mobile Target
> **Stories Verified**:
> - `story-001`: 3D Island Terrain, Water & RTS Camera
> - `story-002`: Resource Gathering & Villager Economy
> - `story-003`: Building Placement & Construction System
> - `story-004`: Barracks, Unit Training & Squad Combat
> - `story-005`: Harbor, Ship Construction & Sea Transit
> - `story-006`: Enemy Island Camp & Amphibious Raids
> - `story-007`: Age Advancement, RTS HUD & Game Loop

---

## Retained Visual Evidence

![Island Empire Gameplay Screenshot](/Users/cuong.le/.gemini/antigravity/brain/b9a26684-bcb9-45b2-b368-254796cbd74d/island-empire-gameplay.png)

---

## Verified Criteria Matrix

| Story | Feature | Verified Behavior | Status |
|---|---|---|---|
| **001** | Island & Ocean | 3D procedural low-poly island with sand beach, grass plateau, and animated tropical water shader. | PASS |
| **001** | RTS Camera | Smooth pan (WASD / middle drag), smooth zoom (scroll wheel / pinch), rotation (Q / E). Clamped bounds. | PASS |
| **002** | Resources | Pine trees (Wood), Boulders (Stone), Berry bushes (Food), Gold veins spawn with harvestable reserves. | PASS |
| **002** | Villagers | Click/tap to select with selection ring; right-click node to harvest; deposits to Town Center; backpack visual. | PASS |
| **003** | Buildings | 6 building types in `BuildingData`; construction drawer on HUD; ghost preview with validity shaders. | PASS |
| **004** | Combat Units | Barracks trains Spearmen (melee) and Archers (ranged); drag-box selection; projectile arrow physics. | PASS |
| **005** | Naval Fleet | Harbor builds Galley Transport; holds up to 8 troops; traverses sea channel to Island 2 shore; disembarks. | PASS |
| **006** | Enemy Base | Island 2 holds Totem Shrine, Watchtowers, and Barbarian defenders. Automated landing raids trigger. | PASS |
| **007** | RTS HUD | Real-time top bar resource meters, speed controls (0x, 1x, 2x), Age advancement button, victory popup. | PASS |
