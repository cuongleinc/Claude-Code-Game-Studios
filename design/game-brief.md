# Game Brief: Island Empire

**One-sentence pitch:** A 3D real-time strategy city-builder where you grow a stone-age village into a thriving maritime realm, build a fleet, and conquer neighboring islands across historical ages.

## Core loop
- **GATHER & BUILD**: Direct villagers to harvest wood, food, stone, and gold to construct housing, resource storehouses, farms, and military barracks.
- **ADVANCE & DEFEND**: Tech up from the Stone Age to the Bronze Age to unlock advanced military units and fortify coastal defenses against pirate raids.
- **SAIL & CONQUER**: Construct a harbor and transport fleet, load armed expeditions, cross the open sea, and defeat rival chieftains to claim their islands as tributary territories.

## Player goal & fail state — what "working" looks like
- **Goal / Win Condition**: Successfully build an expedition fleet, navigate to the rival enemy island, destroy their garrison center, and claim their totem shrine to advance to the Bronze Age and unite the first two islands.
- **Fail State**: Enemy raiding parties wipe out all villagers and destroy the starting Town Center, with insufficient resources remaining to train replacements.

## MVP — what must exist to be the game
- **1. Island Terrain & Touch RTS Camera**: Stylized 3D island terrain with navmesh navigation, pan/zoom/rotate gestures, and camera clamping.
- **2. Villager Economy & Resource Loop**: Wood, stone, food, and gold gathering, drop-off logic at storehouses, and a population cap system.
- **3. Building Placement & Construction**: Touch-friendly building grid/snapping, construction progress, and 6 core structures (Town Center, House, Farm, Lumber Camp, Barracks, Harbor).
- **4. Unit Training & Squad Tactical Orders**: Villager, Spearman, and Archer training with drag-select box, tap-to-select, and context-sensitive attack/move/gather commands.
- **5. Harbor & Naval Expedition**: Shipyard construction, transport galley production, embarkation/disembarkation mechanics, and open water sea-lane transit.
- **6. Enemy Island & Threat AI**: Rival settlement that manages defense patrols and dispatches periodic amphibious raiding parties against the player's colony.
- **7. Age Advancement & Save/Load**: Stone Age to Bronze Age tech unlock requirements, building visual upgrades, and persistent game state serialization.

## Out of scope — not building this
- No Iron, Medieval, or Gunpowder Ages in the vertical slice (strictly Stone & Bronze Age scope).
- No hero units, commander ability cooldowns, or relic powers.
- No multiplayer, online matchmaking, or cloud save synchronization.
- No simultaneous multi-island live simulation (conquered islands become passive tributary estates).
- No complex multi-faction diplomacy or neutral trade caravans.

## Build order
1. **Camera & Navigable Island Environment**: 3D low-poly island mesh, Godot touch camera rig (pan/zoom/rotate), and 3D navigation mesh.
2. **Resource Nodes & Villager Gathering**: Trees, rocks, and berries with villager gathering states, inventory backpacks, and Town Center drop-offs.
3. **Building Construction System**: Placement ghost preview, validity collision checks, foundation building, and population cap integration.
4. **Barracks & Combat Mechanics**: Spearmen and Archer unit classes, ranged/melee combat calculations, health bars, and touch squad command system.
5. **Harbor & Sea Transit**: Harbor dock construction, transport ship entity, troop boarding/unboarding, and sea pathfinding to Island 2.
6. **Enemy AI & Raiding**: Enemy island camp, defensive guard radius, and periodic raid waves landing on player beaches.
7. **Age Advancement & Progression**: Stone → Bronze Age cost check, architectural model swaps, and save/load system.

---
**Who it's for / what they feel:** Strategy and city-builder players who crave the empire-building progression of *Age of Empires* packaged into accessible, tactile 20–30 minute mobile gaming sessions.

**Art & audio direction:** Vibrant low-poly 3D models with crisp outlines and readable silhouettes, dynamic tropical turquoise ocean shaders, and calming acoustic panpipes transitioning to driving war percussion during raids.

**Reference game:** *Age of Empires II* meets *Kingdom Two Crowns* and *Polytopia* — distilling the historic economy-into-military loop and island expansion into an intuitive touch-driven experience.

## Open Design Questions & Brainstorm Decisions
1. **Pacing: Pausable Real-Time (1x / 2x / Pause)**:
   - *Decision*: Include a tactical pause and 2x fast-forward button in the HUD.
   - *Rationale*: Mobile screen interaction requires forgiveness; players need to be able to pause during surprise raids to inspect alerts and queue building tasks without high-APM anxiety.
2. **Combat: Touch-Optimized Squad Orders**:
   - *Decision*: Smart tap-to-command with squad selection (tap unit, double-tap type, or drag-select box).
   - *Rationale*: Eliminates fussy micro-positioning while retaining tactical control (spearmen in front to tank, archers behind).
3. **Naval Combat: Amphibious Transports & Deck Archery**:
   - *Decision*: For the Stone and Bronze Ages, ships serve as armed transports holding up to 8 units, where embarked archers can fire on shoreline defenders. Dedicated cannon warships are deferred to later historical eras.
4. **Conquered Islands: Tributary Estates with Fast Travel**:
   - *Decision*: Once an island is subdued, its status changes to an Allied Tributary generating passive resource income. Only one island is actively simulated in 3D physics at a time, keeping mobile performance within budget.
