# PixelLab MCP — Studio Asset Pipeline Integration

This document defines the integration between **Claude Code Game Studios** and the **PixelLab MCP Server (`pixellab`)** for automated, high-fidelity pixel art generation.

---

## 1. Overview & Capabilities

The studio is configured with `pixellab` as the primary asset generator (`art.generator: pixellab` in `project.yaml`).

### Available Toolsets:

1. **Character Creation & Animation**:
   - `create_character` / `create_character_pro_flash`: Generates multi-directional character sprites (idle, directional turnarounds).
   - `create_character_state`: Adds animation states (walking, running, attack, crouch).
   - `animate_character` / `animate_with_skeleton_v3`: Generates smooth frame animations and skeletal transitions.
   - `create_portrait_character`: Dialogue avatars and dialogue box portraits.
   - `create_talking_gif` / `get_lip_sync`: Animated dialogue heads and lip sync.

2. **Tilesets & Environments**:
   - `create_topdown_tileset` / `create_tiles_pro`: Autotiles, ground textures, and wall tilesets for top-down games.
   - `create_sidescroller_tileset`: Platforms, slopes, backgrounds, and foregrounds for 2D platformers.
   - `create_isometric_tile`: Isometric floor and wall tiles.
   - `create_path_tiles`: Path transitions and terrain blending.
   - `create_building_kit`: Modular architectural elements.

3. **Objects, Props & Rooms**:
   - `create_1_direction_object` / `create_8_direction_object`: World interactables, chests, trees, and obstacles.
   - `create_room` / `cut_out_room_furniture`: Complete interior scene generation and prop extraction.

4. **UI & Retro Fonts**:
   - `create_ui_asset`: Buttons, frames, health bars, inventory slots, and icons.
   - `create_font`: Retro pixel typography and bitmap fonts.

5. **Fine Control & VFX**:
   - `pixelart_workbench`: Direct programmatic editing, drawing, and inspection of pixel art frames.
   - `vfx_workbench`: Frame-by-frame animated effects (slashes, spells, explosions, auras).
   - `edit_image_pro_flash` / `inpaint_image`: Selective modifications and targeted repairs.
   - `reduce_colors` / `correct_pixelart`: Palette enforcement and pixel-grid alignment.

---

## 2. Workflow Integration

### `/art-bible` (Visual Identity)
- Sets base pixel grid (e.g. 16×16, 24×24, 32×32 or 48×48).
- Defines indexed color palette (e.g. Endesga 32, Pico-8, Sweetie 16, or custom studio palette).
- Establishes outline rules (black outline, selective outline / sel-out, or lineless).

### `/asset-spec` (Asset Specifications)
- When generating asset specs for 2D sprites, tilesets, or UI, prompts are tailored for PixelLab parameters (grid dimension, angle, palette constraints).
- Calls to `pixellab` MCP tools are executed to generate the asset directly into `assets/` or `src/` following the naming convention:
  `assets/[category]/[category]_[name]_[variant]_[size].png`

### `/dev-story` (Implementation)
- Programmer agents (`gameplay-programmer`, `ui-programmer`) and `technical-artist` reference generated pixel art assets and wire them into scene files (`.tscn` for Godot, prefabs for Unity/Unreal).
- Ensures proper texture filtering: **Nearest Neighbor / Point** (no bilinear smoothing) to preserve crisp pixel edges.
