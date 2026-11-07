# Characters, Combat Units & Enemy Factions GDD

> **Status**: Approved
> **Author**: Lead Game Designer & Combat Specialist
> **Last Updated**: 2026-11-07
> **Last Verified**: 2026-11-07
> **Implements Pillar**: Satisfying Growth, Meaningful Risk, Island Warfare

## Summary
This document specifies the complete roster of playable characters, economic villagers, military combat units, hero commanders, and hostile enemy factions for *Island Empire*. It defines their combat roles, damage formulas, movement attributes, visual identities, and enemy raid escalation curves across all four historical eras (Stone, Bronze, Iron, and Medieval).

> **Quick reference** — Layer: `Core & Feature` · Priority: `Vertical Slice & Full Vision` · Key deps: `GameManager`, `BuildingBase`, `UnitBase`, `CombatSystem`

---

## Overview
Units in *Island Empire* are the core agents through which players interact with the world: gathering resources, constructing civil and military infrastructure, repelling hostile island incursions, and embarking on fleets to conquer adjacent lands. 

Units follow a classic RTS rock-paper-scissors counter dynamic augmented by maritime and siege warfare:
- **Infantry (Spearmen / Barbarians)**: Durable frontline anchors; strong against cavalry and raiders.
- **Archers / Skirmishers**: Long-range support; counters light infantry; fragile when swarmed in melee.
- **Cavalry (Royal Knights)**: High speed shock flankers; destroys archers and isolated villagers.
- **Siege (Catapults / Bombardiers)**: Extreme range and area destruction; devastates fortifications and buildings.
- **Naval (Galleys / War Galleons)**: Sea lane control and amphibious shoreline bombardment.
- **Commanders (Heroes & Bosses)**: High-HP linchpins granting tactical auras and rally boosts.

---

## Player Fantasy
*"I land as a humble outcast with three villagers, but through steel, stone, and tactical command, I raise a grand royal army led by chivalric knights and battle-hardened galleons that sweeps away pirate armadas."*

---

## Factions

### 1. The Isle Kingdom (Player Faction)
- **Identity**: Royal maritime settlers expanding across the archipelago.
- **Colors**: Imperial Blue (`#3377dd`) & Polished Gold (`#ffdd44`).
- **Doctrine**: Balanced economy, disciplined formations, heavy defensive masonry, and naval supremacy.

### 2. The Red Corsair Syndicate (Enemy Raiders)
- **Identity**: Cutthroat pirates operating from secret coves and sunken atolls.
- **Colors**: Blood Crimson (`#b32020`) & Charcoal Black (`#222226`).
- **Doctrine**: High-speed amphibious skiffs, cutlass rushers, incendiary bombs, and hit-and-run pillaging of coastal storehouses.

### 3. The Ash Isle Barbarians (Island Hostiles)
- **Identity**: Fierce native clan defending their sacred volcanic shrines and gold veins.
- **Colors**: Ochre Orange (`#d06010`) & Bone White (`#e8dfc8`).
- **Doctrine**: Heavy melee rage, high damage clubs and axes, poisoned darts, and high initial wave pressure.

---

## Player Unit Roster

### 1. Villager (Civil Worker)
- **Role**: Economic backbone. Fells timber, quarries stone, fishes/farms food, mines gold, and constructs all buildings.
- **Age Requirement**: Stone Age
- **Trained At**: Town Center
- **Cost**: 50 Food
- **Stats**:
  - Max HP: 60
  - Attack: 6 (Fists / Wood axe)
  - Speed: 5.2 m/s
  - Range: 1.5 m
  - Gather Rate: 10 resources / 2.5s
  - Carry Capacity: 20 units

### 2. Spearman (Basic Line Infantry)
- **Role**: Early frontline defender and anti-cavalry specialist.
- **Age Requirement**: Stone Age
- **Trained At**: Barracks
- **Cost**: 60 Food, 30 Wood
- **Stats**:
  - Max HP: 130
  - Attack: 18
  - Speed: 6.0 m/s
  - Range: 2.0 m
  - Attack Cooldown: 1.1s
  - Armor: Light

### 3. Archer (Ranged Marksman)
- **Role**: Concentrated fire support; picks off raiders before they reach walls.
- **Age Requirement**: Bronze Age
- **Trained At**: Barracks
- **Cost**: 50 Food, 50 Wood
- **Stats**:
  - Max HP: 80
  - Attack: 14
  - Speed: 6.2 m/s
  - Range: 14.0 m
  - Attack Cooldown: 1.6s
  - Projectile: Flight Arrow (22 m/s)

### 4. Royal Knight (Heavy Shock Cavalry)
- **Role**: Fast strike unit. Rushes siege engines and breaks archer lines.
- **Age Requirement**: Iron Age
- **Trained At**: Barracks
- **Cost**: 100 Food, 80 Gold
- **Stats**:
  - Max HP: 260
  - Attack: 32
  - Speed: 8.5 m/s
  - Range: 2.4 m
  - Attack Cooldown: 1.2s
  - Passive: Lance Charge (+15 bonus damage on first strike after moving > 10m)

### 5. Siege Catapult (Heavy Artillery)
- **Role**: Breaches enemy palisades and pulverizes defensive clusters.
- **Age Requirement**: Iron Age
- **Trained At**: Siege Workshop
- **Cost**: 150 Wood, 100 Stone, 50 Gold
- **Stats**:
  - Max HP: 220
  - Attack: 45 (AoE splash 3.5m)
  - Speed: 3.4 m/s
  - Range: 24.0 m
  - Attack Cooldown: 3.5s
  - Projectile: Heavy Stone Boulder (18 m/s, high arc)

### 6. Island Lord (Hero Commander)
- **Role**: Unique faction leader. Buffs all friendly units in radius.
- **Age Requirement**: Bronze Age
- **Trained At**: Town Center (Limit 1 active)
- **Cost**: 150 Food, 150 Gold
- **Stats**:
  - Max HP: 300
  - Attack: 28
  - Speed: 6.4 m/s
  - Range: 2.2 m
  - Attack Cooldown: 1.0s
  - Special Ability: *Inspiring Aura* (12m aura granting nearby allies +20% move speed and +5 attack damage)

---

## Enemy Unit Roster

### 1. Ash Isle Barbarian (Frontline Berserker)
- **Role**: Savage melee fighter wielding heavy spiked wooden clubs.
- **Faction**: Ash Isle Clan
- **Stats**:
  - Max HP: 110
  - Attack: 15
  - Speed: 5.8 m/s
  - Range: 1.8 m
  - Attack Cooldown: 1.2s
  - Behavior: Charges nearest player building or resource-gathering villager.

### 2. Corsair Raider (Pirate Swashbuckler)
- **Role**: Fast amphibious raider armed with dual steel cutlasses.
- **Faction**: Red Corsair Syndicate
- **Stats**:
  - Max HP: 125
  - Attack: 20
  - Speed: 6.6 m/s
  - Range: 1.8 m
  - Attack Cooldown: 0.95s
  - Behavior: Disembarks near docks and targets economy storage and gold deposits.

### 3. Corsair Bomb-Hurler (Incendiary Demolitionist)
- **Role**: Throws exploding gunpowder kegs over walls and into troop clusters.
- **Faction**: Red Corsair Syndicate
- **Stats**:
  - Max HP: 90
  - Attack: 30 (AoE splash 2.5m)
  - Speed: 5.4 m/s
  - Range: 12.0 m
  - Attack Cooldown: 2.8s
  - Target Priority: Buildings, Walls, Guard Towers

### 4. Dread Captain "Barnaby Flint" (Pirate Warlord Boss)
- **Role**: Leader of the Red Corsair armada. Deadly in melee with flintlock pistol blasts.
- **Faction**: Red Corsair Syndicate
- **Stats**:
  - Max HP: 650
  - Attack: 40
  - Speed: 6.0 m/s
  - Range: 3.0 m (Melee saber) / 10.0 m (Flintlock shot every 4s)
  - Special: *Pirate Warcry* — causes nearby corsairs to move 25% faster for 6s.

### 5. Chieftain "Gorgar Ironbone" (Clan Chief Boss)
- **Role**: Mountainous barbarian chief guarding the volcanic fortress.
- **Faction**: Ash Isle Clan
- **Stats**:
  - Max HP: 750
  - Attack: 48
  - Speed: 5.2 m/s
  - Range: 2.5 m
  - Special: *Earth Slam* — deals 30 area damage to all adjacent foes.

---

## Combat Formulas & Balance Rules

### Damage Formula
```
DamageDealt = max(1, BaseAttack - ArmorValue) * TypeMultiplier
```
Where `TypeMultiplier`:
- Spearman vs. Cavalry = `1.75x`
- Knight vs. Archer / Villager = `1.5x`
- Catapult / Bomb-Hurler vs. Building = `2.0x`
- Archer vs. Light Infantry = `1.2x`

### Raid Escalation Wave Table
| Wave | Game Time | Faction | Composition | Objective |
|------|-----------|---------|-------------|-----------|
| 1 | 2:00 | Barbarians | 2 Barbarians | Harass outer villagers |
| 2 | 4:30 | Barbarians | 3 Barbarians, 1 Raider | Attack nearest camp |
| 3 | 7:00 | Corsairs | 3 Corsair Raiders, 1 Bomb-Hurler | Target storehouse & harbor |
| 4 | 10:30 | Mixed Warband | 4 Raiders, 2 Bomb-Hurlers, 2 Barbarians | Coordinated beachhead assault |
| 5 (Boss) | 14:00 | Corsair Armada | Dread Captain Flint + 5 Raiders + 2 Galleons | Full conquest offensive |

---

## Visual & Audio Identity (PixelLab Spec)

| Entity | Silhouette / Weapon | Palette | Pixel Art Dimensions |
|--------|---------------------|---------|----------------------|
| **Villager** | Tunic, leather belt, timber axe | Brown, Beige, Cream | 32x32 / 48x48 |
| **Spearman** | Bronze helm, tall ash spear, wooden buckler | Bronze, Navy, Sand | 32x32 / 48x48 |
| **Archer** | Feathered cap, recurve longbow, quiver | Forest Green, Tan | 32x32 / 48x48 |
| **Royal Knight** | Full plate armor, warhorse, grand lance | Royal Blue, Silver, Gold | 64x64 |
| **Catapult** | Timber wheeled siege carriage, tension arm | Dark Oak, Iron Gray | 64x64 |
| **Island Lord** | Crown, ermine-lined blue cape, gilded broadsword | Gold, Ultramarine, Scarlet | 64x64 |
| **Corsair Raider** | Bandana, eyepatch, crossed dual cutlasses | Crimson, Dark Charcoal | 32x32 / 48x48 |
| **Dread Captain** | Tricorn hat with skull crest, long frock coat | Deep Wine Red, Brass | 64x64 |
| **Clan Berserker**| Spiked club, bone charms, tribal tattoos | Ochre, Muddy Brown | 32x32 / 48x48 |
| **Clan Chieftain** | Horned beast skull helm, mammoth bone greataxe | Ash Black, Crimson | 64x64 |
