# Character & Enemy Visual Asset Specifications

> **Status**: Approved
> **Pipeline**: PixelLab MCP Pixel Art
> **Resolution Standard**: 64x64 (Bosses & Heroes), 32x32 / 48x48 (Troops & Skirmishers)

## Overview
This document specifies the sprite and billboard generation briefs for all playable characters, military units, and enemy raiders in *Island Empire*. Assets are generated using the `pixellab` MCP server and rendered in Godot 4.7 using `Sprite3D` billboards with `TEXTURE_FILTER_NEAREST` or 2D UI avatar panels.

---

## 1. Playable Kingdom Units

### Asset: `royal_knight.png`
- **Category**: Playable Military Unit (Cavalry)
- **Dimensions**: 64x64 px, Transparent PNG
- **Visual Description**: Gallant medieval knight in polished steel plate armor mounted on a white warhorse with imperial blue caparison, carrying a long jousting lance with a golden pennon.
- **PixelLab MCP Prompt**: `pixel art 64x64 sprite of a noble medieval royal knight in shining silver plate armor on horseback holding a long lance with royal blue and gold flag, clean pixel art, transparent background`

### Asset: `archer.png`
- **Category**: Playable Military Unit (Ranged)
- **Dimensions**: 48x48 px, Transparent PNG
- **Visual Description**: Keen-eyed archer wearing a green tunic, brown leather bracers, and a feathered cap, drawing a tall yew recurve bow with an arrow knocked.
- **PixelLab MCP Prompt**: `pixel art 48x48 sprite of a medieval archer in green tunic with leather bracers drawing a wooden longbow with an arrow, quiver on back, clean retro pixel art, transparent background`

---

## 2. Red Corsair Syndicate (Pirate Enemies)

### Asset: `corsair_raider.png`
- **Category**: Hostile Marauder (Melee Infantry)
- **Dimensions**: 48x48 px, Transparent PNG
- **Visual Description**: Rogue pirate raider with a crimson bandana, eye patch, striped mariner shirt, and dual curved cutlasses ready to slash.
- **PixelLab MCP Prompt**: `pixel art 48x48 sprite of a fierce pirate corsair raider with red bandana, eye patch, striped shirt, wielding dual steel cutlasses, dynamic combat stance, transparent background`

### Asset: `dread_captain.png`
- **Category**: Hostile Warlord (Boss)
- **Dimensions**: 64x64 px, Transparent PNG
- **Visual Description**: Feared pirate warlord in an ornate black-and-gold tricorn hat with skull badge, long blood-red naval overcoat, holding a golden saber and flintlock pistol.
- **PixelLab MCP Prompt**: `pixel art 64x64 sprite of a terrifying dread pirate captain with ornate tricorn hat with skull crest, long crimson velvet frock coat, holding a cutlass saber and flintlock pistol, boss character, transparent background`

---

## 3. Ash Isle Clan (Tribal Barbarians)

### Asset: `clan_berserker.png`
- **Category**: Hostile Savage (Heavy Melee)
- **Dimensions**: 48x48 px, Transparent PNG
- **Visual Description**: Tribal warrior with fierce red war paint across chest and face, fur pelt loincloth, swinging a giant spiked wooden war club.
- **PixelLab MCP Prompt**: `pixel art 48x48 sprite of a tribal barbarian berserker warrior with red body war paint, fur pelt armor, wielding a heavy spiked wooden club, fierce aggressive stance, transparent background`

### Asset: `clan_chieftain.png`
- **Category**: Hostile Warlord (Boss)
- **Dimensions**: 64x64 px, Transparent PNG
- **Visual Description**: Imposing tribal chieftain wearing an ancient horned beast skull helmet, mammoth tooth necklace, and wielding a colossal stone greataxe.
- **PixelLab MCP Prompt**: `pixel art 64x64 sprite of a giant tribal barbarian chieftain wearing a horned beast skull helmet, fur cloak, wielding a massive stone battleaxe, warlord boss, transparent background`
