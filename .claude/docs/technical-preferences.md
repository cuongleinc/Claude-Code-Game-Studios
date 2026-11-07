# Technical Preferences

<!-- project.yaml at the repo root is the machine-readable source of truth for
     engine, specialists, naming, performance, platform, and testing.framework.
     This file is the human-readable LEGACY FALLBACK: agents and skills resolve
     each key from project.yaml first and fall back here only when the
     project.yaml key is absent. /setup-engine dual-writes both.
     Forbidden patterns and allowed libraries are NOT migrated — they live only
     in this file. Populated by /setup-engine; updated as decisions are made. -->

## Engine & Language

- **Engine**: Godot 4.7
- **Language**: GDScript
- **Rendering**: Mobile (Vulkan Mobile)
- **Physics**: Jolt 3D

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile (iOS, Android) primary; Desktop (macOS, Windows, Linux) secondary
- **Input Methods**: Touch (tap, drag-select, pinch-zoom), Keyboard/Mouse on desktop
- **Primary Input**: Touch
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: High-contrast readable silhouettes at mobile scale; generous tap targets (min 48x48dp)

## Naming Conventions

- **Classes**: PascalCase
- **Variables**: snake_case
- **Signals/Events**: past_tense (e.g. `building_constructed`, `unit_died`)
- **Files**: snake_case (`.gd`, `.tscn`)
- **Scenes/Prefabs**: snake_case (`.tscn`)
- **Constants**: SCREAMING_SNAKE

## Performance Budgets

- **Target Framerate**: 60 FPS (30 FPS power-save fallback on mobile)
- **Frame Budget**: 16.6ms
- **Draw Calls**: < 150 per frame
- **Memory Ceiling**: < 512 MB RAM on mobile devices

## Testing

- **Framework**: gdUnit4
- **Minimum Coverage**: Core economy & combat logic
- **Required Tests**: Balance formulas, Age progression, gather rates, island conquer conditions

## Asset Pipeline & Art Generation

- **Art Style**: Pixel Art
- **Generator**: PixelLab MCP (`pixellab`)
- **Capabilities**:
  - Characters: Multi-directional character generation (`create_character`, `create_character_pro_flash`, `create_character_state`)
  - Animations: Sprite animation & lip sync (`animate_character`, `animate_with_skeleton_v3`, `create_talking_gif`)
  - Tilesets: Top-down, sidescroller, and isometric tiles (`create_topdown_tileset`, `create_sidescroller_tileset`, `create_isometric_tile`, `create_tiles_pro`)
  - Objects: 1-direction & 8-direction map objects, room cut-outs (`create_1_direction_object`, `create_8_direction_object`, `create_map_object`, `create_room`)
  - UI: Pixel art UI elements, buttons, panels, custom pixel fonts (`create_ui_asset`, `create_font`)
  - VFX & Tooling: Pixel workbench and VFX workbench (`pixelart_workbench`, `vfx_workbench`, `edit_image_pro_flash`, `reduce_colors`, `correct_pixelart`)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist
- **Shader Specialist**: godot-shader-specialist
- **UI Specialist**: godot-specialist
- **Additional Specialists**: godot-gdextension-specialist
- **Routing Notes**: Use GDScript for gameplay and UI; use Godot shaders for water and environment effects; consult GDExtension if high-throughput pathfinding or simulation needs C++

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (`.gd`) | godot-gdscript-specialist |
| Shader / material files (`.gdshader`) | godot-shader-specialist |
| UI / screen files (`.tscn` under UI/) | godot-specialist |
| Scene / prefab / level files (`.tscn`) | godot-specialist |
| Native extension / plugin files | godot-gdextension-specialist |
| General architecture review | godot-specialist |
