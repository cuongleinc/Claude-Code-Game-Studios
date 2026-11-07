"""
Master Artisan Procedural 3D Asian Pagoda & Architecture Generator for Island Empire
Faithfully replicates the exact style and composition of the user's reference image:
- Seamless multi-layered flared pagoda roofs with glazed dark blue-grey slate tiles
- Rich terracotta / cinnabar ridge beams and golden finials
- Upper wooden balcony with carved post railings
- Prominent stone brick chimney on the left side
- Front entrance portico with small tiled roof, double wooden doors, red scrolls & lion knockers
- Iconic circular Moon Window with wooden lattice grille
- Warm glowing red lanterns suspended with dark cords flanking gates and under balconies
- Stone entrance steps, garden stone tea table, and bonsai cloud pine
- Aligned to Godot camera view (Blender -Y -> Godot +Z South)
"""

import bpy
import math
import os

OUTPUT_DIR = "/Users/cuong.le/Document/build-the-game/assets/models"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# -----------------------------------------------------------------------------
# PALETTE MATCHING REFERENCE IMAGE
# -----------------------------------------------------------------------------
def create_mat(name, color_rgba, roughness=0.6, metallic=0.0, emission_rgba=None, emission_strength=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color_rgba
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        if emission_rgba and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emission_rgba
            bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat

def get_palette():
    return {
        # Timbers
        "timber": create_mat("Timber", (0.22, 0.13, 0.08, 1.0), roughness=0.75),
        "timber_dark": create_mat("TimberDark", (0.13, 0.08, 0.05, 1.0), roughness=0.8),
        "timber_red": create_mat("TimberRed", (0.35, 0.12, 0.09, 1.0), roughness=0.65),
        "plaster": create_mat("Plaster", (0.90, 0.87, 0.80, 1.0), roughness=0.85),
        
        # Stones
        "stone_base": create_mat("StoneBase", (0.28, 0.30, 0.26, 1.0), roughness=0.9),
        "stone_brick": create_mat("StoneBrick", (0.75, 0.72, 0.68, 1.0), roughness=0.8),
        
        # Roofs (Rich glazed navy/charcoal slate blue + terracotta cinnabar trim)
        "roof_tile": create_mat("RoofTile", (0.12, 0.16, 0.22, 1.0), roughness=0.45),
        "roof_ridge": create_mat("RoofRidge", (0.32, 0.10, 0.08, 1.0), roughness=0.55),
        
        # Accents
        "lantern_red": create_mat("LanternRed", (0.95, 0.06, 0.06, 1.0), roughness=0.35, emission_rgba=(1.0, 0.12, 0.12, 1.0), emission_strength=2.8),
        "gold_brass": create_mat("GoldBrass", (0.95, 0.72, 0.18, 1.0), roughness=0.25, metallic=0.88),
        "foliage": create_mat("PineFoliage", (0.08, 0.24, 0.10, 1.0), roughness=0.85),
        "cord_dark": create_mat("CordDark", (0.08, 0.08, 0.08, 1.0), roughness=0.9)
    }

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

# -----------------------------------------------------------------------------
# PRIMITIVES
# -----------------------------------------------------------------------------
def box(name, size, loc, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if mat:
        obj.data.materials.append(mat)
    return obj

def cylinder(name, radius, height, loc, mat, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    if mat:
        obj.data.materials.append(mat)
    return obj

def sphere(name, radius, loc, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    if mat:
        obj.data.materials.append(mat)
    return obj

# -----------------------------------------------------------------------------
# LANTERN HELPER (SOLID SUSPENDED LANTERN)
# -----------------------------------------------------------------------------
def add_hanging_lantern(name, loc, cord_top_z, mats):
    lx, ly, lz = loc
    # Suspension Cord
    cord_len = max(0.08, cord_top_z - lz)
    cylinder(name + "_Cord", 0.015, cord_len, (lx, ly, lz + cord_len * 0.5), mats["cord_dark"])
    # Brass Cap
    cylinder(name + "_Cap", 0.08, 0.04, (lx, ly, lz + 0.13), mats["gold_brass"])
    # Red Paper Body
    cylinder(name + "_Body", 0.12, 0.24, (lx, ly, lz), mats["lantern_red"])
    # Bottom Ring & Tassel
    cylinder(name + "_Ring", 0.07, 0.03, (lx, ly, lz - 0.13), mats["gold_brass"])
    cylinder(name + "_Tassel", 0.03, 0.12, (lx, ly, lz - 0.20), mats["gold_brass"])

# -----------------------------------------------------------------------------
# ARTISANAL PAGODA ROOF GENERATOR (CLEAN GEOMETRY, NO FLOATING ARTIFACTS)
# -----------------------------------------------------------------------------
def build_pagoda_roof(name, w, d, h, base_z, mats, has_ridge_finials=True):
    half_w = w * 0.5
    half_d = d * 0.5

    # 1. Main Roof Hip (Glazed blue-grey slate tiles)
    r_diag = max(half_w, half_d) * 1.41421356
    bpy.ops.mesh.primitive_cone_add(
        vertices=4,
        radius1=r_diag,
        radius2=r_diag * 0.22,
        depth=h,
        location=(0, 0, base_z + h * 0.5),
        rotation=(0, 0, math.pi * 0.25)
    )
    roof = bpy.context.active_object
    roof.name = name + "_Tiles"
    roof.scale = (w / max(w, d), d / max(w, d), 1.0)
    bpy.ops.object.transform_apply(scale=True)
    roof.data.materials.append(mats["roof_tile"])

    # 2. Lower Eaves Fascia Board (Timber Trim underneath)
    box(name + "_EavesTrim", (w * 0.98, d * 0.98, 0.08), (0, 0, base_z + 0.04), mats["roof_ridge"])

    # 3. Terracotta Ridge Beam & Dragon Finials
    ridge_w = max(w, d) * 0.42
    box(name + "_Ridge", (ridge_w, 0.22, 0.18), (0, 0, base_z + h + 0.05), mats["roof_ridge"])
    if has_ridge_finials:
        for rx in [-ridge_w * 0.5, ridge_w * 0.5]:
            box(name + "_Finial", (0.16, 0.16, 0.25), (rx, 0, base_z + h + 0.15), mats["gold_brass"])

def export_glb(filepath):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format='GLB',
        use_selection=True,
        export_apply=True
    )
    print("Exported GLB to:", filepath)

# -----------------------------------------------------------------------------
# 1. ASIAN PAVILION COTTAGE / HOUSE (REFERENCE IMAGE REPLICA)
# Facade faces -Y (Godot +Z South, looking straight at player camera)
# -----------------------------------------------------------------------------
def build_asian_house():
    clear_scene()
    mats = get_palette()

    # 1. Mossy Stone Plinth Foundation
    box("Foundation", (3.2, 3.2, 0.4), (0, 0, 0.2), mats["stone_base"])

    # 2. Entrance Stone Steps leading down towards front (-Y)
    for i in range(3):
        box(f"Step_{i}", (1.3 - i * 0.1, 0.32, 0.10), (0.0, -1.55 - i * 0.22, 0.05 + (2 - i) * 0.1), mats["stone_brick"])

    # Stone garden pathway pavers
    for py in [-2.3, -2.6, -2.9]:
        box(f"Paver_{py}", (0.55, 0.26, 0.06), (0.1, py, 0.03), mats["stone_brick"])
        box(f"PaverR_{py}", (0.45, 0.24, 0.06), (0.75, py + 0.1, 0.03), mats["stone_brick"])

    # 3. Ground Floor Plaster Walls & Timber Posts
    box("GroundPlaster", (2.8, 2.8, 1.8), (0, 0, 1.3), mats["plaster"])
    for px in [-1.35, 1.35]:
        for py in [-1.35, 1.35]:
            box("Post", (0.20, 0.20, 1.8), (px, py, 1.3), mats["timber"])

    # 4. Front Entrance Portico & Double Wooden Door (Facing -Y)
    box("DoorFrame", (1.2, 0.12, 1.35), (0.0, -1.41, 1.05), mats["timber_dark"])
    box("DoorPanels", (1.0, 0.06, 1.25), (0.0, -1.43, 1.0), mats["timber"])
    # Red Couplets (春聯)
    box("ScrollL", (0.13, 0.03, 0.75), (-0.56, -1.42, 1.05), mats["lantern_red"])
    box("ScrollR", (0.13, 0.03, 0.75), (0.56, -1.42, 1.05), mats["lantern_red"])
    # Brass Lion Knockers
    sphere("KnockerL", 0.05, (-0.2, -1.46, 1.05), mats["gold_brass"])
    sphere("KnockerR", 0.05, (0.2, -1.46, 1.05), mats["gold_brass"])

    # Door Portico Awning (Small tiled roof over entrance)
    box("PorticoRoof", (1.6, 0.65, 0.12), (0.0, -1.65, 1.95), mats["roof_tile"])
    box("PorticoTrim", (1.65, 0.70, 0.06), (0.0, -1.65, 1.90), mats["roof_ridge"])

    # Two Entrance Red Lanterns flanking the door under the portico
    add_hanging_lantern("LanternDoorL", (-0.72, -1.60, 1.50), 1.90, mats)
    add_hanging_lantern("LanternDoorR", (0.72, -1.60, 1.50), 1.90, mats)

    # 5. Side Latticed Window (West wall)
    box("WinFrameL", (0.08, 0.65, 0.65), (-1.41, 0.1, 1.3), mats["timber_dark"])
    box("WinLatticeL", (0.06, 0.55, 0.55), (-1.41, 0.1, 1.3), mats["timber"])

    # 6. Prominent Stone Brick Chimney (Left side, extending past roof)
    box("ChimneyBody", (0.55, 0.55, 4.3), (-1.42, 0.1, 2.55), mats["stone_brick"])
    box("ChimneyTop", (0.70, 0.70, 0.16), (-1.42, 0.1, 4.75), mats["stone_base"])

    # 7. First-Floor Overhanging Eaves Roof
    build_pagoda_roof("RoofMid", 3.2, 3.2, 0.65, 2.2, mats, has_ridge_finials=False)

    # 8. Second Floor Balcony & Chamber
    # Front-facing Balcony
    box("BalconyFloor", (2.7, 1.3, 0.12), (0, -0.85, 2.95), mats["timber"])
    # Balcony Railing (Front and sides)
    box("RailingFront", (2.7, 0.08, 0.45), (0, -1.46, 3.22), mats["timber_dark"])
    box("RailingL", (0.08, 1.3, 0.45), (-1.31, -0.85, 3.22), mats["timber_dark"])
    box("RailingR", (0.08, 1.3, 0.45), (1.31, -0.85, 3.22), mats["timber_dark"])

    # Upper Chamber (Warm Plaster & Timber)
    box("UpperChamber", (2.1, 1.9, 1.4), (0, 0.15, 3.65), mats["timber"])
    box("UpperFrontPlaster", (1.9, 0.08, 1.25), (0.0, -0.81, 3.65), mats["plaster"])

    # Iconic Circular Moon Window (Center of upper front wall)
    cylinder("MoonWindowRing", 0.38, 0.10, (0.0, -0.87, 3.75), mats["timber_dark"], rot=(math.pi * 0.5, 0, 0))
    cylinder("MoonWindowCenter", 0.30, 0.06, (0.0, -0.87, 3.75), mats["timber"], rot=(math.pi * 0.5, 0, 0))

    # Two Upper Red Lanterns hanging under upper balcony corners
    add_hanging_lantern("LanternUpperL", (-1.15, -1.15, 3.75), 4.35, mats)
    add_hanging_lantern("LanternUpperR", (1.15, -1.15, 3.75), 4.35, mats)

    # 9. Top Pagoda Roof
    build_pagoda_roof("RoofTop", 2.6, 2.6, 0.85, 4.35, mats, has_ridge_finials=True)

    # 10. Garden Bonsai Cloud Pine & Stone Furniture
    # Bonsai Cloud Pine (Left of porch)
    cylinder("BonsaiTrunk", 0.08, 0.70, (-1.35, -1.45, 0.50), mats["timber_dark"], rot=(0.1, -0.15, 0.2))
    sphere("BonsaiPad1", 0.35, (-1.28, -1.45, 0.90), mats["foliage"])
    sphere("BonsaiPad2", 0.26, (-1.48, -1.55, 1.20), mats["foliage"])
    sphere("BonsaiRock1", 0.25, (-1.45, -1.75, 0.15), mats["stone_base"])
    sphere("BonsaiRock2", 0.20, (-1.15, -1.75, 0.12), mats["stone_base"])

    # Stone Tea Table & Stools (Right of porch)
    cylinder("TableTop", 0.36, 0.07, (1.45, -1.35, 0.52), mats["stone_base"])
    cylinder("TablePillar", 0.12, 0.45, (1.45, -1.35, 0.26), mats["stone_base"])
    cylinder("Stool1", 0.16, 0.24, (1.25, -1.75, 0.22), mats["stone_base"])
    cylinder("Stool2", 0.16, 0.24, (1.75, -1.45, 0.22), mats["stone_base"])

    export_glb(os.path.join(OUTPUT_DIR, "house.glb"))

# -----------------------------------------------------------------------------
# 2. GRAND IMPERIAL PAGODA PALACE (TOWN CENTER)
# Facade faces -Y (Godot +Z South, looking straight at player camera)
# -----------------------------------------------------------------------------
def build_asian_town_center():
    clear_scene()
    mats = get_palette()

    # 1. Imperial Stone Plinth
    box("PalaceBase", (5.2, 5.2, 0.55), (0, 0, 0.275), mats["stone_base"])
    box("FrontStairs1", (2.4, 0.8, 0.18), (0, -2.8, 0.10), mats["stone_brick"])
    box("FrontStairs2", (2.0, 0.6, 0.18), (0, -2.6, 0.25), mats["stone_brick"])

    # 2. Ground Floor Hall & Grand Vermilion Pillars
    box("MainHallPlaster", (4.4, 4.4, 2.2), (0, 0, 1.65), mats["plaster"])
    for cx in [-2.0, -0.7, 0.7, 2.0]:
        cylinder(f"RedPillarFront_{cx}", 0.18, 2.2, (cx, -2.22, 1.65), mats["lantern_red"])
        cylinder(f"RedPillarBack_{cx}", 0.18, 2.2, (cx, 2.22, 1.65), mats["timber"])

    # Grand Palace Double Gate
    box("PalaceGate", (1.8, 0.14, 1.7), (0.0, -2.22, 1.4), mats["timber_dark"])
    box("ImperialPlaque", (2.0, 0.1, 0.45), (0.0, -2.25, 2.45), mats["timber_red"])
    box("GoldenSeal", (0.7, 0.12, 0.3), (0.0, -2.27, 2.45), mats["gold_brass"])

    # 2 Red Lanterns flanking the Palace Gate
    add_hanging_lantern("LanternTC_L", (-1.2, -2.15, 1.95), 2.5, mats)
    add_hanging_lantern("LanternTC_R", (1.2, -2.15, 1.95), 2.5, mats)

    # 3. Tier 1 Grand Pagoda Roof
    build_pagoda_roof("RoofTier1", 4.8, 4.8, 1.1, 2.75, mats, has_ridge_finials=False)

    # 4. Tier 2 Upper Hall with Moon Windows
    box("UpperHall", (3.0, 3.0, 1.7), (0, 0, 4.15), mats["plaster"])
    for px in [-1.45, 1.45]:
        for py in [-1.45, 1.45]:
            box("UpperPost", (0.16, 0.16, 1.7), (px, py, 4.15), mats["timber"])

    cylinder("MoonWindowFront", 0.45, 0.08, (0, -1.52, 4.25), mats["gold_brass"], rot=(math.pi*0.5, 0, 0))

    # 5. Tier 2 Pagoda Roof
    build_pagoda_roof("RoofTier2", 3.4, 3.4, 0.95, 5.0, mats, has_ridge_finials=True)

    # 6. Imperial Golden Spire
    cylinder("SpireBase", 0.30, 0.45, (0, 0, 6.2), mats["gold_brass"])
    cylinder("SpireShaft", 0.08, 1.2, (0, 0, 7.0), mats["gold_brass"])
    sphere("SpireOrb", 0.24, (0, 0, 7.35), mats["gold_brass"])

    export_glb(os.path.join(OUTPUT_DIR, "town_center.glb"))

# -----------------------------------------------------------------------------
# 3. ASIAN PAGODA GUARD TOWER
# -----------------------------------------------------------------------------
def build_asian_guard_tower():
    clear_scene()
    mats = get_palette()

    box("TowerBase", (2.2, 2.2, 0.6), (0, 0, 0.3), mats["stone_base"])

    # Tier 1
    box("TowerT1", (1.6, 1.6, 1.8), (0, 0, 1.5), mats["plaster"])
    for px in [-0.78, 0.78]:
        for py in [-0.78, 0.78]:
            cylinder("TowerCol1", 0.11, 1.8, (px, py, 1.5), mats["timber"])
    build_pagoda_roof("TRoof1", 1.9, 1.9, 0.5, 2.4, mats, has_ridge_finials=False)

    # Tier 2
    box("TowerT2", (1.3, 1.3, 1.7), (0, 0, 3.4), mats["timber"])
    build_pagoda_roof("TRoof2", 1.6, 1.6, 0.45, 4.25, mats, has_ridge_finials=False)

    # Tier 3 (Archer Balcony)
    box("ArcherFloor", (1.5, 1.5, 0.12), (0, 0, 4.75), mats["timber"])
    for rx in [-0.72, 0.72]:
        box("ArcherRailX", (0.08, 1.5, 0.42), (rx, 0, 5.0), mats["timber_dark"])
    for ry in [-0.72, 0.72]:
        box("ArcherRailY", (1.5, 0.08, 0.42), (0, ry, 5.0), mats["timber_dark"])

    # 4 Corner Archer Posts
    for px in [-0.65, 0.65]:
        for py in [-0.65, 0.65]:
            cylinder("ArcherPost", 0.08, 1.1, (px, py, 5.3), mats["timber"])

    # 2 Red Lanterns under Archer Balcony
    add_hanging_lantern("LanternTowerL", (-0.55, -0.55, 4.3), 4.75, mats)
    add_hanging_lantern("LanternTowerR", (0.55, -0.55, 4.3), 4.75, mats)

    # Top Roof
    build_pagoda_roof("TRoofTop", 1.8, 1.8, 0.6, 5.85, mats, has_ridge_finials=True)
    sphere("TowerPeak", 0.2, (0, 0, 6.6), mats["gold_brass"])

    export_glb(os.path.join(OUTPUT_DIR, "guard_tower.glb"))

# -----------------------------------------------------------------------------
# 4. ASIAN MARTIAL DOJO / BARRACKS
# -----------------------------------------------------------------------------
def build_asian_barracks():
    clear_scene()
    mats = get_palette()

    box("DojoBase", (4.4, 3.2, 0.4), (0, 0, 0.2), mats["stone_base"])
    box("DojoHall", (3.8, 2.6, 1.9), (0, 0, 1.35), mats["plaster"])

    # Vermilion front columns
    for cx in [-1.8, -0.6, 0.6, 1.8]:
        cylinder(f"DojoColF_{cx}", 0.13, 1.9, (cx, -1.32, 1.35), mats["lantern_red"])
        cylinder(f"DojoColB_{cx}", 0.13, 1.9, (cx, 1.32, 1.35), mats["timber"])

    # Dojo Gate & Kanji plaque
    box("DojoGate", (1.5, 0.12, 1.5), (0, -1.33, 1.1), mats["timber_dark"])
    box("DojoSign", (1.4, 0.08, 0.35), (0, -1.35, 2.0), mats["timber_red"])

    # Martial Weapons Training Rack (placed at front porch)
    box("RackL", (0.08, 0.08, 0.9), (1.4, -1.55, 0.65), mats["timber"])
    box("RackR", (0.08, 0.08, 0.9), (1.9, -1.55, 0.65), mats["timber"])
    box("RackBar", (0.55, 0.06, 0.06), (1.65, -1.55, 0.85), mats["timber_dark"])
    cylinder("Spear1", 0.03, 1.1, (1.55, -1.57, 0.85), mats["gold_brass"], rot=(0, 0.35, 0))
    cylinder("Spear2", 0.03, 1.1, (1.75, -1.57, 0.85), mats["gold_brass"], rot=(0, -0.35, 0))

    # 2 Red Lanterns flanking Dojo entrance
    add_hanging_lantern("LanternDojoL", (-1.1, -1.35, 1.85), 2.3, mats)
    add_hanging_lantern("LanternDojoR", (1.1, -1.35, 1.85), 2.3, mats)

    # Curved Dojo Pagoda Roof
    build_pagoda_roof("DojoRoof", 4.3, 3.1, 1.0, 2.3, mats, has_ridge_finials=True)

    export_glb(os.path.join(OUTPUT_DIR, "barracks.glb"))

# -----------------------------------------------------------------------------
# 5. STYLIZED BONSAI CLOUD PINE TREE
# -----------------------------------------------------------------------------
def build_asian_pine_tree():
    clear_scene()
    mats = get_palette()

    cylinder("TrunkBase", 0.26, 1.2, (0.0, 0.0, 0.6), mats["timber_dark"])
    cylinder("TrunkMid", 0.20, 1.1, (0.12, 0.06, 1.5), mats["timber_dark"], rot=(0.12, -0.1, 0.15))
    cylinder("TrunkUpper", 0.15, 1.0, (0.04, -0.08, 2.3), mats["timber_dark"], rot=(-0.08, 0.15, -0.08))

    # Branch 1 & Cloud Foliage Pad 1
    cylinder("BranchL", 0.09, 0.75, (-0.4, 0.15, 1.7), mats["timber_dark"], rot=(0.35, -0.55, 0))
    sphere("CloudPad1", 0.7, (-0.75, 0.3, 1.85), mats["foliage"])
    pad1 = bpy.context.active_object
    pad1.scale = (1.2, 1.1, 0.38)
    bpy.ops.object.transform_apply(scale=True)

    # Branch 2 & Cloud Foliage Pad 2
    cylinder("BranchR", 0.08, 0.65, (0.4, -0.15, 2.15), mats["timber_dark"], rot=(-0.25, 0.45, 0))
    sphere("CloudPad2", 0.6, (0.7, -0.25, 2.35), mats["foliage"])
    pad2 = bpy.context.active_object
    pad2.scale = (1.1, 1.0, 0.35)
    bpy.ops.object.transform_apply(scale=True)

    # Crown Cloud Foliage Pad
    sphere("CloudPadCrown", 0.8, (0.05, -0.05, 3.0), mats["foliage"])
    pad3 = bpy.context.active_object
    pad3.scale = (1.25, 1.15, 0.42)
    bpy.ops.object.transform_apply(scale=True)

    # Mossy Base Rocks
    sphere("BaseRock1", 0.38, (0.35, 0.25, 0.18), mats["stone_base"])
    sphere("BaseRock2", 0.28, (-0.3, 0.35, 0.14), mats["stone_base"])

    export_glb(os.path.join(OUTPUT_DIR, "pine_tree.glb"))

if __name__ == "__main__":
    print("=== REBUILDING CLEAN ARTISAN ASIAN ARCHITECTURE ===")
    build_asian_house()
    build_asian_town_center()
    build_asian_guard_tower()
    build_asian_barracks()
    build_asian_pine_tree()
    print("=== ARTISAN GENERATION COMPLETE ===")
