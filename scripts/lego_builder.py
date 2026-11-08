#!/usr/bin/env python3
"""
lego_builder.py
High-Fidelity LEGO Architectural & Modular Kit Assembler for Island Empire.
Generates genuine LEGO-style models with:
- Authentic LEGO proportions (studs, plates, bricks, slope roofs, crenellations)
- Individual staggered brick courses with visible mortar seams and bevels
- Iconic LEGO color palette (Medium Stone Grey, Dark Stone Grey, Bright Red, Reddish Brown, Pearl Gold)
- Integrated decals (dragon shields, arched wooden gates, candlelight windows, archery targets)
- Modular assemblies for:
  * Town Center (Imperial Castle Keep with 4 Bastions, Arched Gate, Pagoda Roofs, and Golden Spires)
  * Pagoda Cottage (Staggered Brick Walls, Upturned Pagoda Eaves, Chimney, Lantern)
  * Military Barracks (Stockade Palisade, Training Dummy with Target, Observation Cupola, Shields)
  * Guard Watchtower (Stone Bastion, Arrow Slits, Corbelled Deck, Signal Fire Brazier)
  * Nature Assets (Pine Tree with 8-sided needle tiers, Faceted Boulder, Gold Ore Deposit, Berry Bush)
"""

import sys
import os
import math
import bpy
import mathutils

# LEGO Standard Metric Unit Dimensions (in game meters)
# 1 stud = 0.8m width/length
# 1 plate = 0.32m height (3 plates = 1 standard brick = 0.96m)
# 1 stud = 0.22m radius, 0.14m height
U = 0.8
PLATE_H = 0.32
BRICK_H = PLATE_H * 3.0
STUD_R = 0.22
STUD_H = 0.14
SEAM = 0.018 # Crisp brick joint seam gap

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_lego_material(name: str, base_color: tuple, roughness: float = 0.26, metallic: float = 0.0, emission: tuple = None) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = 0.65
        elif "Specular" in bsdf.inputs:
            bsdf.inputs["Specular"].default_value = 0.65
        if emission:
            bsdf.inputs["Emission Color"].default_value = emission
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = 3.0
    return mat

def create_decal_material(name: str, texture_path: str) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")

    if os.path.isfile(texture_path):
        img = bpy.data.images.load(texture_path)
        tex_node = nodes.new("ShaderNodeTexImage")
        tex_node.image = img
        tex_node.interpolation = "Closest"
        links.new(tex_node.outputs["Color"], bsdf.inputs["Base Color"])
        if bsdf:
            bsdf.inputs["Roughness"].default_value = 0.22
    return mat

MATERIALS = {}
def init_materials():
    # Official LEGO Color Matches
    # Medium Stone Grey / Light Bluish Gray (#9C9C9C)
    MATERIALS["STONE_GREY"] = create_lego_material("Mat_StoneGrey", (0.52, 0.55, 0.58, 1.0), roughness=0.28)
    # Dark Stone Grey / Dark Bluish Gray (#595D60)
    MATERIALS["DARK_GREY"] = create_lego_material("Mat_DarkGrey", (0.28, 0.30, 0.33, 1.0), roughness=0.28)
    # Bright Red (#C91A09)
    MATERIALS["RED"] = create_lego_material("Mat_Red", (0.82, 0.10, 0.08, 1.0), roughness=0.22)
    # Dark Red (#720E0F)
    MATERIALS["DARK_RED"] = create_lego_material("Mat_DarkRed", (0.46, 0.08, 0.08, 1.0), roughness=0.25)
    # Warm Tan / Brick Yellow (#D9BB7B / #E4CD9E)
    MATERIALS["TAN"] = create_lego_material("Mat_Tan", (0.86, 0.78, 0.65, 1.0), roughness=0.26)
    MATERIALS["WHITE"] = create_lego_material("Mat_White", (0.92, 0.91, 0.88, 1.0), roughness=0.24)
    # Reddish Brown (#582A12)
    MATERIALS["BROWN"] = create_lego_material("Mat_Brown", (0.36, 0.20, 0.12, 1.0), roughness=0.30)
    MATERIALS["DARK_BROWN"] = create_lego_material("Mat_DarkBrown", (0.22, 0.12, 0.07, 1.0), roughness=0.32)
    # Pearl Gold (#AA7F2E / #DEAC34)
    MATERIALS["GOLD"] = create_lego_material("Mat_Gold", (0.92, 0.72, 0.14, 1.0), roughness=0.18, metallic=0.35)
    # Royal Blue (#0055BF)
    MATERIALS["BLUE"] = create_lego_material("Mat_Blue", (0.08, 0.30, 0.72, 1.0), roughness=0.24)
    # Dark Green (#184E29)
    MATERIALS["GREEN"] = create_lego_material("Mat_Green", (0.10, 0.45, 0.15, 1.0), roughness=0.25)
    # Bright Green / Lime (#4B9F4A)
    MATERIALS["LIME"] = create_lego_material("Mat_Lime", (0.35, 0.68, 0.18, 1.0), roughness=0.25)
    # Trans-Flame
    MATERIALS["FLAME"] = create_lego_material("Mat_Flame", (1.0, 0.5, 0.05, 1.0), roughness=0.10, emission=(1.0, 0.45, 0.05, 1.0))

    # PixelLab Decals
    decal_dir = "/Users/cuong.le/Document/build-the-game/assets/lego"
    MATERIALS["DECAL_DOOR"] = create_decal_material("Mat_DecalDoor", f"{decal_dir}/decal_door.png")
    MATERIALS["DECAL_SHIELD"] = create_decal_material("Mat_DecalShield", f"{decal_dir}/decal_shield.png")
    MATERIALS["DECAL_WINDOW"] = create_decal_material("Mat_DecalWindow", f"{decal_dir}/decal_window.png")
    MATERIALS["DECAL_TARGET"] = create_decal_material("Mat_DecalTarget", f"{decal_dir}/decal_target.png")

# Geometry Helpers
def add_stud(x: float, y: float, z: float, mat_name: str = "STONE_GREY"):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12,
        radius=STUD_R,
        depth=STUD_H,
        location=(x, y, z + STUD_H / 2.0)
    )
    obj = bpy.context.active_object
    obj.data.materials.append(MATERIALS[mat_name])
    return obj

def add_single_brick(gx: float, gy: float, gz_plates: int, studs_x: int, studs_y: int, height_plates: int = 3, mat_name: str = "STONE_GREY", studs: bool = True):
    """Adds a single discrete LEGO brick with distinct seam clearance and studs."""
    w = studs_x * U - SEAM
    l = studs_y * U - SEAM
    h = height_plates * PLATE_H - SEAM * 0.5
    cx = gx * U + (studs_x * U) / 2.0
    cy = gy * U + (studs_y * U) / 2.0
    cz = gz_plates * PLATE_H + (height_plates * PLATE_H) / 2.0

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, cy, cz))
    obj = bpy.context.active_object
    obj.scale = (w, l, h)
    bpy.ops.object.transform_apply(scale=True)
    obj.data.materials.append(MATERIALS[mat_name])

    if studs:
        top_z = gz_plates * PLATE_H + height_plates * PLATE_H
        for ix in range(studs_x):
            for iy in range(studs_y):
                sx = gx * U + (ix + 0.5) * U
                sy = gy * U + (iy + 0.5) * U
                add_stud(sx, sy, top_z, mat_name)
    return obj

def add_brick_wall(start_gx: int, start_gy: int, start_gz_plates: int, studs_length: int, thickness_studs: int, height_bricks: int, axis: str = "X", mat_name: str = "STONE_GREY", studs: bool = False):
    """
    Builds a realistic LEGO masonry wall out of interlocking 1x2, 1x4 and 2x2 bricks
    with authentic staggered brick courses!
    """
    for b_idx in range(height_bricks):
        cur_z = start_gz_plates + b_idx * 3
        is_top = (b_idx == height_bricks - 1) and studs
        offset = (b_idx % 2) * 1 # stagger by 1 stud every layer

        pos = 0
        while pos < studs_length:
            # Choose brick size: 4, 2, or 1
            remaining = studs_length - pos
            if pos == 0 and offset == 1 and remaining > 1:
                cur_len = 1
            elif remaining >= 4:
                cur_len = 4
            elif remaining >= 2:
                cur_len = 2
            else:
                cur_len = 1

            if axis == "X":
                add_single_brick(start_gx + pos, start_gy, cur_z, cur_len, thickness_studs, height_plates=3, mat_name=mat_name, studs=is_top)
            else:
                add_single_brick(start_gx, start_gy + pos, cur_z, thickness_studs, cur_len, height_plates=3, mat_name=mat_name, studs=is_top)
            pos += cur_len

def add_slope_brick(gx: float, gy: float, gz_plates: int, studs_x: int, studs_y: int, slope_dir: str = "+Y", height_plates: int = 3, mat_name: str = "RED"):
    """Creates a 45-degree LEGO slope brick."""
    w = studs_x * U - SEAM
    l = studs_y * U - SEAM
    h = height_plates * PLATE_H - SEAM * 0.5
    x0 = gx * U + SEAM * 0.5
    y0 = gy * U + SEAM * 0.5
    z0 = gz_plates * PLATE_H

    verts = [
        (x0, y0, z0),          # 0: bottom-SW
        (x0 + w, y0, z0),      # 1: bottom-SE
        (x0 + w, y0 + l, z0),  # 2: bottom-NE
        (x0, y0 + l, z0),      # 3: bottom-NW
    ]

    if slope_dir == "+Y": # Slopes down towards +Y (front)
        verts.extend([
            (x0, y0, z0 + h),          # 4: top-SW
            (x0 + w, y0, z0 + h),      # 5: top-SE
            (x0 + w, y0 + l, z0),      # 6: top-NE (base)
            (x0, y0 + l, z0),          # 7: top-NW (base)
        ])
    elif slope_dir == "-Y": # Slopes down towards -Y (back)
        verts.extend([
            (x0, y0, z0),              # 4
            (x0 + w, y0, z0),          # 5
            (x0 + w, y0 + l, z0 + h),  # 6
            (x0, y0 + l, z0 + h),      # 7
        ])
    elif slope_dir == "+X": # Slopes down towards +X (right)
        verts.extend([
            (x0, y0, z0 + h),          # 4
            (x0 + w, y0, z0),          # 5
            (x0 + w, y0 + l, z0),      # 6
            (x0, y0 + l, z0 + h),      # 7
        ])
    else: # Slopes down towards -X (left)
        verts.extend([
            (x0, y0, z0),              # 4
            (x0 + w, y0, z0 + h),      # 5
            (x0 + w, y0 + l, z0 + h),  # 6
            (x0, y0 + l, z0),          # 7
        ])

    faces = [
        (0, 1, 2, 3), # Bottom
        (4, 5, 6, 7), # Slope
        (0, 4, 7, 3), # Left
        (1, 2, 6, 5), # Right
        (0, 1, 5, 4), # Back
        (3, 7, 6, 2), # Front
    ]

    mesh = bpy.data.meshes.new("SlopeMesh")
    obj = bpy.data.objects.new("SlopeObj", mesh)
    bpy.context.collection.objects.link(obj)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.data.materials.append(MATERIALS[mat_name])
    return obj

def add_crenellation(gx: float, gy: float, gz_plates: int, studs_x: int, studs_y: int, mat_name: str = "STONE_GREY"):
    """Castle parapet battlements with merlons and embrasures."""
    # Base walkway plate
    add_single_brick(gx, gy, gz_plates, studs_x, studs_y, height_plates=1, mat_name="DARK_GREY", studs=False)
    # Merlons around perimeter
    for ix in range(studs_x):
        for iy in range(studs_y):
            # Only perimeter
            is_edge = (ix == 0 or ix == studs_x - 1 or iy == 0 or iy == studs_y - 1)
            if is_edge and (ix + iy) % 2 == 0:
                add_single_brick(gx + ix, gy + iy, gz_plates + 1, 1, 1, height_plates=2, mat_name=mat_name, studs=True)

def add_cylinder_brick(gx: float, gy: float, gz_plates: int, radius_studs: float = 0.5, height_plates: int = 3, mat_name: str = "BROWN", stud: bool = True):
    cx = (gx + 0.5) * U
    cy = (gy + 0.5) * U
    h = height_plates * PLATE_H - SEAM * 0.5
    cz = gz_plates * PLATE_H + (height_plates * PLATE_H) / 2.0

    bpy.ops.mesh.primitive_cylinder_add(
        vertices=16,
        radius=radius_studs * U - SEAM * 0.5,
        depth=h,
        location=(cx, cy, cz)
    )
    obj = bpy.context.active_object
    obj.data.materials.append(MATERIALS[mat_name])

    if stud:
        add_stud(cx, cy, gz_plates * PLATE_H + height_plates * PLATE_H, mat_name)
    return obj

def add_cone(cx: float, cy: float, cz: float, radius: float, height: float, mat_name: str = "GREEN"):
    bpy.ops.mesh.primitive_cone_add(
        vertices=16,
        radius1=radius,
        radius2=0.04,
        depth=height,
        location=(cx, cy, cz + height / 2.0)
    )
    obj = bpy.context.active_object
    obj.data.materials.append(MATERIALS[mat_name])
    return obj

def add_decal_tile(cx: float, cy: float, cz: float, width: float, height: float, decal_mat_name: str, normal: str = "+Y"):
    """Places a printed LEGO tile decal."""
    bpy.ops.mesh.primitive_plane_add(size=1.0)
    plane = bpy.context.active_object
    plane.data.materials.append(MATERIALS[decal_mat_name])

    if normal == "+Y":
        plane.rotation_euler = (math.radians(90), 0, 0)
        plane.scale = (width, height, 1.0)
    elif normal == "-Y":
        plane.rotation_euler = (math.radians(-90), 0, 0)
        plane.scale = (width, height, 1.0)
    elif normal == "+X":
        plane.rotation_euler = (0, math.radians(90), 0)
        plane.scale = (height, width, 1.0)
    elif normal == "-X":
        plane.rotation_euler = (0, math.radians(-90), 0)
        plane.scale = (height, width, 1.0)

    plane.location = (cx, cy, cz)
    return plane

# =========================================================================
# 1. LEGO IMPERIAL TOWN CENTER / CASTLE KEEP
# =========================================================================
def build_lego_town_center(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Foundation (14x12 studs)
    add_single_brick(-7, -6, 0, 14, 12, height_plates=1, mat_name="DARK_GREY", studs=True)

    # 4 Corner Watchtower Bastions (3x3 studs each, 5 bricks tall = 15 plates)
    towers = [(-6, -5), (3, -5), (-6, 2), (3, 2)]
    for tx, ty in towers:
        # Masonry stone walls
        add_brick_wall(tx, ty, 1, 3, 3, height_bricks=5, axis="X", mat_name="STONE_GREY")
        # Overhanging battlement deck with crenellations
        add_crenellation(tx - 0.5, ty - 0.5, 16, 4, 4, mat_name="STONE_GREY")
        # Corner gold spire finial on each tower
        add_cone((tx + 1.5) * U, (ty + 1.5) * U, 19 * PLATE_H, 0.40, 1.3, "GOLD")

    # Curtain Walls (Connecting towers to gatehouse)
    add_brick_wall(-3, -5, 1, 2, 2, height_bricks=3, axis="X", mat_name="STONE_GREY")
    add_brick_wall(1, -5, 1, 2, 2, height_bricks=3, axis="X", mat_name="STONE_GREY")
    add_crenellation(-3, -5, 10, 2, 2, mat_name="STONE_GREY")
    add_crenellation(1, -5, 10, 2, 2, mat_name="STONE_GREY")

    # Front Gatehouse Arch
    add_single_brick(-1, -5, 1, 2, 2, height_plates=3, mat_name="DARK_GREY", studs=False)
    add_single_brick(-1, -5, 8, 2, 2, height_plates=4, mat_name="STONE_GREY", studs=False)
    # Printed Double Wooden Gate Decal (prominently sized)
    add_decal_tile(0.0, -5 * U - 0.06, 5 * PLATE_H, 2.4, 2.5, "DECAL_DOOR", normal="-Y")
    # Royal Dragon Shield Crest mounted proudly above the gate
    add_decal_tile(0.0, -5 * U - 0.08, 11 * PLATE_H, 1.4, 1.4, "DECAL_SHIELD", normal="-Y")

    # MAIN KEEP - Level 1: Stone Great Hall (8x6 studs, z=1 to z=12)
    add_brick_wall(-4, -3, 1, 8, 6, height_bricks=4, axis="X", mat_name="STONE_GREY")
    # Front Arched Windows with Candlelight
    add_decal_tile(-2.0 * U, -3 * U - 0.05, 6 * PLATE_H, 1.3, 1.3, "DECAL_WINDOW", normal="-Y")
    add_decal_tile(2.0 * U, -3 * U - 0.05, 6 * PLATE_H, 1.3, 1.3, "DECAL_WINDOW", normal="-Y")
    # Side Arched Windows
    add_decal_tile(-4 * U - 0.05, 0.0, 6 * PLATE_H, 1.3, 1.3, "DECAL_WINDOW", normal="-X")
    add_decal_tile(4 * U + 0.05, 0.0, 6 * PLATE_H, 1.3, 1.3, "DECAL_WINDOW", normal="+X")

    # Pagoda Eaves Level 1 (Cantilevered Red Slope Bricks, 10x8 studs, z=13 to z=15)
    for x in range(-5, 5):
        add_slope_brick(x, -4, 13, 1, 1, slope_dir="-Y", height_plates=2, mat_name="RED")
        add_slope_brick(x, 3, 13, 1, 1, slope_dir="+Y", height_plates=2, mat_name="RED")
    for y in range(-3, 3):
        add_slope_brick(-5, y, 13, 1, 1, slope_dir="-X", height_plates=2, mat_name="RED")
        add_slope_brick(4, y, 13, 1, 1, slope_dir="+X", height_plates=2, mat_name="RED")

    # Level 2: Imperial Pavilion (Warm Tan & Timber Columns, 6x4 studs, z=15 to z=24)
    add_brick_wall(-3, -2, 15, 6, 4, height_bricks=3, axis="X", mat_name="TAN")
    # Brown timber-frame corner posts
    add_single_brick(-3, -2, 15, 1, 1, height_plates=9, mat_name="BROWN", studs=False)
    add_single_brick(2, -2, 15, 1, 1, height_plates=9, mat_name="BROWN", studs=False)
    add_single_brick(-3, 1, 15, 1, 1, height_plates=9, mat_name="BROWN", studs=False)
    add_single_brick(2, 1, 15, 1, 1, height_plates=9, mat_name="BROWN", studs=False)
    # Front Candlelight Window on Pavilion
    add_decal_tile(0.0, -2 * U - 0.05, 19 * PLATE_H, 1.3, 1.3, "DECAL_WINDOW", normal="-Y")

    # Pagoda Eaves Level 2 (8x6 studs, z=24 to z=26)
    for x in range(-4, 4):
        add_slope_brick(x, -3, 24, 1, 1, slope_dir="-Y", height_plates=2, mat_name="RED")
        add_slope_brick(x, 2, 24, 1, 1, slope_dir="+Y", height_plates=2, mat_name="RED")
    for y in range(-2, 2):
        add_slope_brick(-4, y, 24, 1, 1, slope_dir="-X", height_plates=2, mat_name="RED")
        add_slope_brick(3, y, 24, 1, 1, slope_dir="+X", height_plates=2, mat_name="RED")

    # Level 3: Golden Observation Throne (4x2 studs, z=26 to z=31)
    add_single_brick(-2, -1, 26, 4, 2, height_plates=5, mat_name="WHITE", studs=False)
    # Golden columns
    add_cylinder_brick(-1.5, -0.8, 26, radius_studs=0.25, height_plates=5, mat_name="GOLD", stud=False)
    add_cylinder_brick(0.5, -0.8, 26, radius_studs=0.25, height_plates=5, mat_name="GOLD", stud=False)
    add_cylinder_brick(-1.5, 0.2, 26, radius_studs=0.25, height_plates=5, mat_name="GOLD", stud=False)
    add_cylinder_brick(0.5, 0.2, 26, radius_studs=0.25, height_plates=5, mat_name="GOLD", stud=False)

    # Top Pagoda Roof (6x4 studs, z=31 to z=34)
    for x in range(-3, 3):
        add_slope_brick(x, -2, 31, 1, 1, slope_dir="-Y", height_plates=3, mat_name="RED")
        add_slope_brick(x, 1, 31, 1, 1, slope_dir="+Y", height_plates=3, mat_name="RED")
    # Golden Ridge and Spire
    add_single_brick(-1, -1, 34, 2, 2, height_plates=2, mat_name="GOLD", studs=True)
    add_cone(0.0, 0.0, 36 * PLATE_H, 0.45, 1.8, "GOLD")
    # Royal Red Pennant Flag
    add_single_brick(0, 0, 39, 2, 1, height_plates=2, mat_name="RED", studs=False)

    export_scene(output_path, target_height=9.0)

# =========================================================================
# 2. LEGO PAGODA COTTAGE / HOUSE
# =========================================================================
def build_lego_house(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Foundation (8x8 studs)
    add_single_brick(-4, -4, 0, 8, 8, height_plates=1, mat_name="DARK_GREY", studs=True)

    # Ground Floor: Warm Tan Masonry Walls (6x6 studs, z=1 to z=10 = 3 bricks tall)
    add_brick_wall(-3, -3, 1, 6, 6, height_bricks=3, axis="X", mat_name="TAN")
    # Brown timber corner columns
    add_single_brick(-3, -3, 1, 1, 1, height_plates=9, mat_name="BROWN", studs=False)
    add_single_brick(2, -3, 1, 1, 1, height_plates=9, mat_name="BROWN", studs=False)
    add_single_brick(-3, 2, 1, 1, 1, height_plates=9, mat_name="BROWN", studs=False)
    add_single_brick(2, 2, 1, 1, 1, height_plates=9, mat_name="BROWN", studs=False)

    # Front Wooden Door Decal & Lantern
    add_decal_tile(0.0, -3 * U - 0.05, 5 * PLATE_H, 1.8, 2.0, "DECAL_DOOR", normal="-Y")
    add_cylinder_brick(1.8, -3.2, 7, radius_studs=0.25, height_plates=2, mat_name="RED", stud=False)

    # Side Arched Window
    add_decal_tile(-3 * U - 0.05, 0.0, 6 * PLATE_H, 1.3, 1.3, "DECAL_WINDOW", normal="-X")

    # Brick Chimney climbing up right flank (22 plates tall)
    add_brick_wall(3, 0, 1, 1, 2, height_bricks=7, axis="Y", mat_name="DARK_RED")
    add_single_brick(3, 0, 22, 1, 2, height_plates=2, mat_name="DARK_GREY", studs=True)

    # Lower Pagoda Roof (Cantilevered Red Slope Bricks, 8x8 studs, z=10 to z=13)
    for x in range(-4, 4):
        add_slope_brick(x, -4, 10, 1, 1, slope_dir="-Y", height_plates=3, mat_name="RED")
        add_slope_brick(x, 3, 10, 1, 1, slope_dir="+Y", height_plates=3, mat_name="RED")
    for y in range(-3, 3):
        add_slope_brick(-4, y, 10, 1, 1, slope_dir="-X", height_plates=3, mat_name="RED")
        add_slope_brick(3, y, 10, 1, 1, slope_dir="+X", height_plates=3, mat_name="RED")

    # Upper Pavilion (4x4 studs, z=13 to z=19 = 2 bricks tall)
    add_brick_wall(-2, -2, 13, 4, 4, height_bricks=2, axis="X", mat_name="TAN")
    add_single_brick(-2, -2, 13, 1, 1, height_plates=6, mat_name="BROWN", studs=False)
    add_single_brick(1, -2, 13, 1, 1, height_plates=6, mat_name="BROWN", studs=False)
    add_single_brick(-2, 1, 13, 1, 1, height_plates=6, mat_name="BROWN", studs=False)
    add_single_brick(1, 1, 13, 1, 1, height_plates=6, mat_name="BROWN", studs=False)
    # Upper window
    add_decal_tile(0.0, -2 * U - 0.05, 16 * PLATE_H, 1.1, 1.1, "DECAL_WINDOW", normal="-Y")

    # Top Pagoda Roof (6x6 red slope roof, z=19 to z=22)
    for x in range(-3, 3):
        add_slope_brick(x, -3, 19, 1, 1, slope_dir="-Y", height_plates=3, mat_name="RED")
        add_slope_brick(x, 2, 19, 1, 1, slope_dir="+Y", height_plates=3, mat_name="RED")
    for y in range(-2, 2):
        add_slope_brick(-3, y, 19, 1, 1, slope_dir="-X", height_plates=3, mat_name="RED")
        add_slope_brick(2, y, 19, 1, 1, slope_dir="+X", height_plates=3, mat_name="RED")

    # Golden Roof Spire Finial
    add_single_brick(-1, -1, 22, 2, 2, height_plates=1, mat_name="GOLD", studs=True)
    add_cone(0.0, 0.0, 23 * PLATE_H, 0.35, 1.2, "GOLD")

    export_scene(output_path, target_height=5.5)

# =========================================================================
# 3. LEGO MILITARY BARRACKS
# =========================================================================
def build_lego_barracks(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Foundation (10x8 studs)
    add_single_brick(-5, -4, 0, 10, 8, height_plates=1, mat_name="DARK_GREY", studs=True)

    # Reddish Brown Timber Log Walls (8x6 studs, 3 bricks tall)
    add_brick_wall(-4, -3, 1, 8, 6, height_bricks=3, axis="X", mat_name="BROWN")
    # Corner dark log posts
    for z in range(1, 10, 3):
        add_single_brick(-4, -3, z, 1, 1, height_plates=3, mat_name="DARK_BROWN", studs=False)
        add_single_brick(3, -3, z, 1, 1, height_plates=3, mat_name="DARK_BROWN", studs=False)
        add_single_brick(-4, 2, z, 1, 1, height_plates=3, mat_name="DARK_BROWN", studs=False)
        add_single_brick(3, 2, z, 1, 1, height_plates=3, mat_name="DARK_BROWN", studs=False)

    # Archery Training Dummy with Target Decal
    add_cylinder_brick(2.5, -3.8, 1, radius_studs=0.25, height_plates=5, mat_name="BROWN", stud=False)
    add_decal_tile(3.0 * U, -3.8 * U - 0.05, 5 * PLATE_H, 1.2, 1.2, "DECAL_TARGET", normal="-Y")

    # Front Entrance Door Decal & Dragon Shield
    add_decal_tile(-1.0 * U, -3 * U - 0.05, 5 * PLATE_H, 1.8, 2.0, "DECAL_DOOR", normal="-Y")
    add_decal_tile(-3.0 * U, -3 * U - 0.05, 6 * PLATE_H, 1.3, 1.3, "DECAL_SHIELD", normal="-Y")

    # Dark Red & Red Slope Roof (10x8 studs, z=10 to z=16)
    for x in range(-5, 5):
        add_slope_brick(x, -4, 10, 1, 1, slope_dir="-Y", height_plates=3, mat_name="DARK_RED")
        add_slope_brick(x, 3, 10, 1, 1, slope_dir="+Y", height_plates=3, mat_name="DARK_RED")
    # Central Ridge Beam
    add_single_brick(-4, -1, 13, 8, 2, height_plates=3, mat_name="RED", studs=True)

    # Observation Loft & Banner Flagpole
    add_crenellation(-1, -1, 16, 2, 2, mat_name="STONE_GREY")
    add_cylinder_brick(0, 0, 18, radius_studs=0.1, height_plates=6, mat_name="GOLD", stud=False)
    add_single_brick(0, 0, 22, 2, 1, height_plates=2, mat_name="RED", studs=False)

    export_scene(output_path, target_height=6.0)

# =========================================================================
# 4. LEGO GUARD WATCHTOWER
# =========================================================================
def build_lego_tower(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Base (6x6 studs)
    add_single_brick(-3, -3, 0, 6, 6, height_plates=1, mat_name="DARK_GREY", studs=True)

    # Tower Shaft: 4x4 studs rising 7 bricks tall (21 plates!)
    add_brick_wall(-2, -2, 1, 4, 4, height_bricks=7, axis="X", mat_name="STONE_GREY")
    # Dark grey corner quoin stones
    for z in range(1, 21, 6):
        add_single_brick(-2, -2, z, 1, 1, height_plates=3, mat_name="DARK_GREY", studs=False)
        add_single_brick(1, -2, z, 1, 1, height_plates=3, mat_name="DARK_GREY", studs=False)
        add_single_brick(-2, 1, z, 1, 1, height_plates=3, mat_name="DARK_GREY", studs=False)
        add_single_brick(1, 1, z, 1, 1, height_plates=3, mat_name="DARK_GREY", studs=False)

    # Front Arched Arrow Slit Window & Shield
    add_decal_tile(0.0, -2 * U - 0.05, 12 * PLATE_H, 1.3, 1.3, "DECAL_WINDOW", normal="-Y")
    add_decal_tile(0.0, -2 * U - 0.05, 6 * PLATE_H, 1.2, 1.2, "DECAL_SHIELD", normal="-Y")

    # Overhanging Corbel Plate (6x6 studs, z=22)
    add_single_brick(-3, -3, 22, 6, 6, height_plates=1, mat_name="DARK_GREY", studs=False)

    # 360-Degree Battlement Parapet with Crenellations (6x6 studs, z=23)
    add_crenellation(-3, -3, 23, 6, 6, mat_name="STONE_GREY")

    # Signal Fire Brazier with vibrant Trans-Orange Flame Piece
    add_cylinder_brick(-0.5, -0.5, 23, radius_studs=0.6, height_plates=2, mat_name="DARK_GREY", stud=False)
    add_cone(0.0, 0.0, 25 * PLATE_H, 0.40, 1.4, "FLAME")

    export_scene(output_path, target_height=7.5)

# =========================================================================
# 5. LEGO NATURE ASSETS
# =========================================================================
def build_lego_tree(output_path: str):
    reset_scene()
    init_materials()

    # Brown Trunk (cylinder bricks)
    add_cylinder_brick(-0.5, -0.5, 0, radius_studs=0.4, height_plates=5, mat_name="BROWN", stud=False)

    # Tiered 8-sided faceted foliage plates with studs (Classic LEGO Pine Tree!)
    # Tier 1 (Wide 6x6 green base with corner chamfers)
    add_single_brick(-3, -3, 5, 6, 6, height_plates=2, mat_name="GREEN", studs=True)
    # Tier 2 (5x5 green tier)
    add_single_brick(-2, -2, 7, 4, 4, height_plates=2, mat_name="GREEN", studs=True)
    # Tier 3 (4x4 bright green / lime highlight tier)
    add_single_brick(-2, -2, 9, 4, 4, height_plates=2, mat_name="LIME", studs=True)
    # Tier 4 (2x2 green peak)
    add_single_brick(-1, -1, 11, 2, 2, height_plates=2, mat_name="GREEN", studs=True)
    # Top Pine Cone Spire
    add_cone(0.0, 0.0, 13 * PLATE_H, 0.45, 1.5, "GREEN")

    export_scene(output_path, target_height=3.6)

def build_lego_stone(output_path: str):
    reset_scene()
    init_materials()

    # Chunky Faceted Boulder made of slope bricks and plates
    add_single_brick(-2, -2, 0, 4, 4, height_plates=1, mat_name="DARK_GREY", studs=True)
    add_slope_brick(-2, -2, 1, 2, 2, slope_dir="-Y", height_plates=3, mat_name="STONE_GREY")
    add_slope_brick(0, -2, 1, 2, 2, slope_dir="+X", height_plates=3, mat_name="DARK_GREY")
    add_slope_brick(-2, 0, 1, 2, 2, slope_dir="-X", height_plates=3, mat_name="DARK_GREY")
    add_slope_brick(0, 0, 1, 2, 2, slope_dir="+Y", height_plates=3, mat_name="STONE_GREY")
    add_single_brick(-1, -1, 4, 2, 2, height_plates=2, mat_name="STONE_GREY", studs=True)

    export_scene(output_path, target_height=1.8)

def build_lego_gold(output_path: str):
    reset_scene()
    init_materials()

    # Dark stone rock vein
    add_single_brick(-2, -2, 0, 4, 4, height_plates=1, mat_name="DARK_GREY", studs=True)
    add_slope_brick(-2, -2, 1, 2, 2, slope_dir="-Y", height_plates=3, mat_name="DARK_GREY")
    add_slope_brick(0, 0, 1, 2, 2, slope_dir="+Y", height_plates=3, mat_name="DARK_GREY")

    # Sparkling Pearl Gold Bricks, Studs, and Crystal Cone
    add_single_brick(-1, -1, 1, 2, 2, height_plates=3, mat_name="GOLD", studs=True)
    add_cylinder_brick(0.2, -0.8, 4, radius_studs=0.3, height_plates=2, mat_name="GOLD", stud=True)
    add_cylinder_brick(-0.8, 0.2, 4, radius_studs=0.3, height_plates=2, mat_name="GOLD", stud=True)
    add_cone(0.0, 0.0, 6 * PLATE_H, 0.38, 1.0, "GOLD")

    export_scene(output_path, target_height=1.6)

def build_lego_berry_bush(output_path: str):
    reset_scene()
    init_materials()

    # Green leaf plates
    add_single_brick(-2, -2, 0, 4, 4, height_plates=2, mat_name="GREEN", studs=True)
    add_single_brick(-1, -1, 2, 2, 2, height_plates=2, mat_name="LIME", studs=True)

    # Bright Red 1x1 Round Stud Berries
    berry_coords = [
        (-1.2, -1.2, 2), (1.2, -1.2, 2), (-1.2, 1.2, 2), (1.2, 1.2, 2),
        (-0.5, 0.5, 4), (0.5, -0.5, 4), (0.0, 0.0, 4)
    ]
    for bx, by, bz in berry_coords:
        add_cylinder_brick(bx, by, bz, radius_studs=0.22, height_plates=1, mat_name="RED", stud=True)

    export_scene(output_path, target_height=1.4)

# =========================================================================
# EXPORT PIPELINE
# =========================================================================
def export_scene(output_path: str, target_height: float):
    bpy.ops.object.select_all(action="SELECT")
    selected_objs = [obj for obj in bpy.context.selected_objects if obj.type == "MESH"]

    if not selected_objs:
        print(f"Error: No meshes to export for {output_path}")
        return

    # Join into a single unified object with preserved material slots
    bpy.context.view_layer.objects.active = selected_objs[0]
    bpy.ops.object.join()
    unified_obj = bpy.context.active_object
    unified_obj.name = "LegoModel"

    # Normalize height and center at ground base (Z=0 at bottom)
    bbox_corners = [unified_obj.matrix_world @ mathutils.Vector(corner) for corner in unified_obj.bound_box]
    min_z = min(c.z for c in bbox_corners)
    max_z = max(c.z for c in bbox_corners)
    current_h = max(0.001, max_z - min_z)
    scale_factor = target_height / current_h

    min_x = min(c.x for c in bbox_corners)
    max_x = max(c.x for c in bbox_corners)
    min_y = min(c.y for c in bbox_corners)
    max_y = max(c.y for c in bbox_corners)
    cx = (min_x + max_x) / 2.0
    cy = (min_y + max_y) / 2.0

    unified_obj.location.x -= cx
    unified_obj.location.y -= cy
    unified_obj.location.z -= min_z
    bpy.ops.object.transform_apply(location=True)

    unified_obj.scale = (scale_factor, scale_factor, scale_factor)
    bpy.ops.object.transform_apply(scale=True)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        use_selection=True,
        export_format="GLB",
        export_materials="EXPORT",
        export_apply=True
    )
    print(f"  Exported LEGO Model -> {output_path} ({len(unified_obj.data.materials)} materials, height={target_height}m)")

if __name__ == "__main__":
    argv = sys.argv
    args = argv[argv.index("--") + 1:] if "--" in argv else argv[1:]
    target = args[0] if len(args) > 0 else "all"

    print("========================================")
    print("      LEGO ARCHITECTURAL ASSEMBLER      ")
    print("========================================")

    models_dir = "/Users/cuong.le/Document/build-the-game/assets/models"

    if target in ["all", "town_center"]:
        print("Assembling LEGO Imperial Town Center...")
        build_lego_town_center(f"{models_dir}/pixel_town_center.glb")

    if target in ["all", "house"]:
        print("Assembling LEGO Pagoda House...")
        build_lego_house(f"{models_dir}/pixel_house.glb")

    if target in ["all", "barracks"]:
        print("Assembling LEGO Barracks...")
        build_lego_barracks(f"{models_dir}/pixel_barracks.glb")

    if target in ["all", "tower"]:
        print("Assembling LEGO Guard Watchtower...")
        build_lego_tower(f"{models_dir}/pixel_tower.glb")
        os.system(f"cp {models_dir}/pixel_tower.glb {models_dir}/pixel_guard_tower.glb")

    if target in ["all", "nature", "tree"]:
        print("Assembling LEGO Pine Tree...")
        build_lego_tree(f"{models_dir}/pixel_tree.glb")

    if target in ["all", "nature", "stone"]:
        print("Assembling LEGO Boulder...")
        build_lego_stone(f"{models_dir}/pixel_stone.glb")

    if target in ["all", "nature", "gold"]:
        print("Assembling LEGO Gold Vein...")
        build_lego_gold(f"{models_dir}/pixel_gold.glb")

    if target in ["all", "nature", "food"]:
        print("Assembling LEGO Berry Bush...")
        build_lego_berry_bush(f"{models_dir}/pixel_food.glb")

    print("\nAll LEGO assemblies generated successfully!")
