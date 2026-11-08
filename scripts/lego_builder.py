#!/usr/bin/env python3
"""
lego_builder.py
High-Fidelity LEGO Architectural & Modular Kit Assembler for Island Empire.
Generates genuine LEGO-style models with:
- 50% smaller micro-LEGO / nanoblock grid resolution for ultra-smooth curves and rich detail
- Authentic LEGO proportions (studs, plates, bricks, slope roofs, crenellations)
- Staggered brick masonry courses with visible mortar seams and bevels
- Official LEGO color palette (Medium Stone Grey, Dark Stone Grey, Bright Red, Reddish Brown, Pearl Gold)
- Integrated decals (dragon shields, arched wooden gates, candlelight windows, archery targets)
- Modular assemblies for:
  * Town Center (Imperial Castle Keep with 4 Bastions, Arched Gate, Pagoda Roofs, and Golden Spires)
  * Pagoda Cottage (Staggered Brick Walls, Upturned Pagoda Eaves, Chimney, Lantern)
  * Military Barracks (Stockade Palisade, Training Dummy with Target, Observation Cupola, Shields)
  * Guard Watchtower (Stone Bastion, Arrow Slits, Corbelled Deck, Signal Fire Brazier)
  * Nature Assets (Pine Tree with 6 needle tiers, Faceted Boulder, Gold Ore Deposit, Berry Bush)
"""

import sys
import os
import math
import bpy
import mathutils

# LEGO Standard Dimensions with 50% Smaller Bricks (Micro-LEGO / Nanoblock Scale)
# 1 stud = 0.4m width/length (was 0.8m)
# 1 plate = 0.16m height (was 0.32m; 3 plates = 1 standard brick = 0.48m)
# 1 stud radius = 0.11m, height = 0.07m
U = 0.4
PLATE_H = 0.16
BRICK_H = PLATE_H * 3.0
STUD_R = 0.11
STUD_H = 0.07
SEAM = 0.009 # Fine brick joint seam gap

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
    MATERIALS["STONE_GREY"] = create_lego_material("Mat_StoneGrey", (0.52, 0.55, 0.58, 1.0), roughness=0.28)
    MATERIALS["DARK_GREY"] = create_lego_material("Mat_DarkGrey", (0.28, 0.30, 0.33, 1.0), roughness=0.28)
    MATERIALS["RED"] = create_lego_material("Mat_Red", (0.82, 0.10, 0.08, 1.0), roughness=0.22)
    MATERIALS["DARK_RED"] = create_lego_material("Mat_DarkRed", (0.46, 0.08, 0.08, 1.0), roughness=0.25)
    MATERIALS["TAN"] = create_lego_material("Mat_Tan", (0.86, 0.78, 0.65, 1.0), roughness=0.26)
    MATERIALS["WHITE"] = create_lego_material("Mat_White", (0.92, 0.91, 0.88, 1.0), roughness=0.24)
    MATERIALS["BROWN"] = create_lego_material("Mat_Brown", (0.36, 0.20, 0.12, 1.0), roughness=0.30)
    MATERIALS["DARK_BROWN"] = create_lego_material("Mat_DarkBrown", (0.22, 0.12, 0.07, 1.0), roughness=0.32)
    MATERIALS["GOLD"] = create_lego_material("Mat_Gold", (0.92, 0.72, 0.14, 1.0), roughness=0.18, metallic=0.35)
    MATERIALS["BLUE"] = create_lego_material("Mat_Blue", (0.08, 0.30, 0.72, 1.0), roughness=0.24)
    MATERIALS["GREEN"] = create_lego_material("Mat_Green", (0.10, 0.45, 0.15, 1.0), roughness=0.25)
    MATERIALS["LIME"] = create_lego_material("Mat_Lime", (0.35, 0.68, 0.18, 1.0), roughness=0.25)
    MATERIALS["FLAME"] = create_lego_material("Mat_Flame", (1.0, 0.5, 0.05, 1.0), roughness=0.10, emission=(1.0, 0.45, 0.05, 1.0))

    decal_dir = "/Users/cuong.le/Document/build-the-game/assets/lego"
    MATERIALS["DECAL_DOOR"] = create_decal_material("Mat_DecalDoor", f"{decal_dir}/decal_door.png")
    MATERIALS["DECAL_SHIELD"] = create_decal_material("Mat_DecalShield", f"{decal_dir}/decal_shield.png")
    MATERIALS["DECAL_WINDOW"] = create_decal_material("Mat_DecalWindow", f"{decal_dir}/decal_window.png")
    MATERIALS["DECAL_TARGET"] = create_decal_material("Mat_DecalTarget", f"{decal_dir}/decal_target.png")

# Geometry Helpers
def add_stud(x: float, y: float, z: float, mat_name: str = "STONE_GREY"):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=10,
        radius=STUD_R,
        depth=STUD_H,
        location=(x, y, z + STUD_H / 2.0)
    )
    obj = bpy.context.active_object
    obj.data.materials.append(MATERIALS[mat_name])
    return obj

def add_single_brick(gx: float, gy: float, gz_plates: int, studs_x: int, studs_y: int, height_plates: int = 3, mat_name: str = "STONE_GREY", studs: bool = True):
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
    """Interlocking staggered brick courses for realistic fine masonry."""
    for b_idx in range(height_bricks):
        cur_z = start_gz_plates + b_idx * 3
        is_top = (b_idx == height_bricks - 1) and studs
        offset = (b_idx % 2) * 2 # 2-stud stagger

        pos = 0
        while pos < studs_length:
            remaining = studs_length - pos
            if pos == 0 and offset == 2 and remaining > 2:
                cur_len = 2
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
    """Creates a 45-degree slope brick."""
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

    if slope_dir == "+Y": # Slopes down towards +Y
        verts.extend([
            (x0, y0, z0 + h),          # 4
            (x0 + w, y0, z0 + h),      # 5
            (x0 + w, y0 + l, z0),      # 6
            (x0, y0 + l, z0),          # 7
        ])
    elif slope_dir == "-Y": # Slopes down towards -Y
        verts.extend([
            (x0, y0, z0),              # 4
            (x0 + w, y0, z0),          # 5
            (x0 + w, y0 + l, z0 + h),  # 6
            (x0, y0 + l, z0 + h),      # 7
        ])
    elif slope_dir == "+X": # Slopes down towards +X
        verts.extend([
            (x0, y0, z0 + h),          # 4
            (x0 + w, y0, z0),          # 5
            (x0 + w, y0 + l, z0),      # 6
            (x0, y0 + l, z0 + h),      # 7
        ])
    else: # Slopes down towards -X
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
    """Battlement parapet with merlons and embrasures."""
    add_single_brick(gx, gy, gz_plates, studs_x, studs_y, height_plates=1, mat_name="DARK_GREY", studs=False)
    for ix in range(0, studs_x, 2):
        for iy in range(0, studs_y, 2):
            is_edge = (ix == 0 or ix >= studs_x - 2 or iy == 0 or iy >= studs_y - 2)
            if is_edge:
                add_single_brick(gx + ix, gy + iy, gz_plates + 1, 2, 2, height_plates=2, mat_name=mat_name, studs=True)

def add_cylinder_brick(gx: float, gy: float, gz_plates: int, radius_studs: float = 1.0, height_plates: int = 3, mat_name: str = "BROWN", stud: bool = True):
    cx = (gx + radius_studs) * U
    cy = (gy + radius_studs) * U
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
        radius2=0.03,
        depth=height,
        location=(cx, cy, cz + height / 2.0)
    )
    obj = bpy.context.active_object
    obj.data.materials.append(MATERIALS[mat_name])
    return obj

def add_decal_tile(cx: float, cy: float, cz: float, width: float, height: float, decal_mat_name: str, normal: str = "+Y"):
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
# 1. LEGO IMPERIAL TOWN CENTER / CASTLE KEEP (50% Smaller Bricks)
# =========================================================================
def build_lego_town_center(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Foundation (28x24 studs)
    add_single_brick(-14, -12, 0, 28, 24, height_plates=2, mat_name="DARK_GREY", studs=True)

    # 4 Corner Watchtower Bastions (6x6 studs each, 10 bricks tall = 30 plates)
    towers = [(-12, -10), (6, -10), (-12, 4), (6, 4)]
    for tx, ty in towers:
        add_brick_wall(tx, ty, 2, 6, 6, height_bricks=10, axis="X", mat_name="STONE_GREY")
        # Overhanging battlement deck with crenellations (8x8 studs)
        add_crenellation(tx - 1, ty - 1, 32, 8, 8, mat_name="STONE_GREY")
        # Corner gold spire finial on each tower
        add_cone((tx + 3) * U, (ty + 3) * U, 36 * PLATE_H, 0.40, 1.5, "GOLD")

    # Curtain Walls (Connecting towers to gatehouse)
    add_brick_wall(-6, -10, 2, 4, 4, height_bricks=6, axis="X", mat_name="STONE_GREY")
    add_brick_wall(2, -10, 2, 4, 4, height_bricks=6, axis="X", mat_name="STONE_GREY")
    add_crenellation(-6, -10, 20, 4, 4, mat_name="STONE_GREY")
    add_crenellation(2, -10, 20, 4, 4, mat_name="STONE_GREY")

    # Front Gatehouse Arch
    add_single_brick(-2, -10, 2, 4, 4, height_plates=6, mat_name="DARK_GREY", studs=False)
    add_single_brick(-2, -10, 16, 4, 4, height_plates=6, mat_name="STONE_GREY", studs=False)
    # Printed Double Wooden Gate Decal
    add_decal_tile(0.0, -10 * U - 0.06, 9 * PLATE_H, 2.6, 2.8, "DECAL_DOOR", normal="-Y")
    # Royal Dragon Shield Crest mounted proudly above the gate
    add_decal_tile(0.0, -10 * U - 0.08, 20 * PLATE_H, 1.5, 1.5, "DECAL_SHIELD", normal="-Y")

    # MAIN KEEP - Level 1: Stone Great Hall (16x12 studs, z=2 to z=26 = 8 bricks tall)
    add_brick_wall(-8, -6, 2, 16, 12, height_bricks=8, axis="X", mat_name="STONE_GREY")
    # Front Arched Windows with Candlelight
    add_decal_tile(-4.0 * U, -6 * U - 0.05, 12 * PLATE_H, 1.4, 1.4, "DECAL_WINDOW", normal="-Y")
    add_decal_tile(4.0 * U, -6 * U - 0.05, 12 * PLATE_H, 1.4, 1.4, "DECAL_WINDOW", normal="-Y")
    # Side Arched Windows
    add_decal_tile(-8 * U - 0.05, 0.0, 12 * PLATE_H, 1.4, 1.4, "DECAL_WINDOW", normal="-X")
    add_decal_tile(8 * U + 0.05, 0.0, 12 * PLATE_H, 1.4, 1.4, "DECAL_WINDOW", normal="+X")

    # Pagoda Eaves Level 1 (20x16 studs red slope bricks, z=26 to z=29)
    for x in range(-10, 10, 2):
        add_slope_brick(x, -8, 26, 2, 2, slope_dir="-Y", height_plates=3, mat_name="RED")
        add_slope_brick(x, 6, 26, 2, 2, slope_dir="+Y", height_plates=3, mat_name="RED")
    for y in range(-6, 6, 2):
        add_slope_brick(-10, y, 26, 2, 2, slope_dir="-X", height_plates=3, mat_name="RED")
        add_slope_brick(8, y, 26, 2, 2, slope_dir="+X", height_plates=3, mat_name="RED")

    # Level 2: Imperial Pavilion (Warm Tan & Timber Columns, 12x8 studs, z=29 to z=47 = 6 bricks tall)
    add_brick_wall(-6, -4, 29, 12, 8, height_bricks=6, axis="X", mat_name="TAN")
    # Brown timber corner posts
    add_single_brick(-6, -4, 29, 2, 2, height_plates=18, mat_name="BROWN", studs=False)
    add_single_brick(4, -4, 29, 2, 2, height_plates=18, mat_name="BROWN", studs=False)
    add_single_brick(-6, 2, 29, 2, 2, height_plates=18, mat_name="BROWN", studs=False)
    add_single_brick(4, 2, 29, 2, 2, height_plates=18, mat_name="BROWN", studs=False)
    # Pavilion front window
    add_decal_tile(0.0, -4 * U - 0.05, 38 * PLATE_H, 1.4, 1.4, "DECAL_WINDOW", normal="-Y")

    # Pagoda Eaves Level 2 (16x12 studs, z=47 to z=50)
    for x in range(-8, 8, 2):
        add_slope_brick(x, -6, 47, 2, 2, slope_dir="-Y", height_plates=3, mat_name="RED")
        add_slope_brick(x, 4, 47, 2, 2, slope_dir="+Y", height_plates=3, mat_name="RED")
    for y in range(-4, 4, 2):
        add_slope_brick(-8, y, 47, 2, 2, slope_dir="-X", height_plates=3, mat_name="RED")
        add_slope_brick(6, y, 47, 2, 2, slope_dir="+X", height_plates=3, mat_name="RED")

    # Level 3: Golden Observation Pavilion (8x4 studs, z=50 to z=59)
    add_single_brick(-4, -2, 50, 8, 4, height_plates=9, mat_name="WHITE", studs=False)
    # Golden columns
    add_cylinder_brick(-3, -1.5, 50, radius_studs=0.5, height_plates=9, mat_name="GOLD", stud=False)
    add_cylinder_brick(2, -1.5, 50, radius_studs=0.5, height_plates=9, mat_name="GOLD", stud=False)
    add_cylinder_brick(-3, 0.5, 50, radius_studs=0.5, height_plates=9, mat_name="GOLD", stud=False)
    add_cylinder_brick(2, 0.5, 50, radius_studs=0.5, height_plates=9, mat_name="GOLD", stud=False)

    # Top Pagoda Roof (12x8 studs, z=59 to z=65)
    for x in range(-6, 6, 2):
        add_slope_brick(x, -4, 59, 2, 2, slope_dir="-Y", height_plates=4, mat_name="RED")
        add_slope_brick(x, 2, 59, 2, 2, slope_dir="+Y", height_plates=4, mat_name="RED")
    # Golden Ridge and Spire
    add_single_brick(-2, -2, 65, 4, 4, height_plates=3, mat_name="GOLD", studs=True)
    add_cone(0.0, 0.0, 68 * PLATE_H, 0.50, 2.2, "GOLD")
    # Royal Red Pennant Flag
    add_single_brick(0, 0, 74, 4, 1, height_plates=4, mat_name="RED", studs=False)

    export_scene(output_path, target_height=9.0)

# =========================================================================
# 2. LEGO PAGODA COTTAGE / HOUSE (50% Smaller Bricks)
# =========================================================================
def build_lego_house(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Foundation (16x16 studs)
    add_single_brick(-8, -8, 0, 16, 16, height_plates=2, mat_name="DARK_GREY", studs=True)

    # Ground Floor: Warm Tan Masonry Walls (12x12 studs, z=2 to z=20 = 6 bricks tall)
    add_brick_wall(-6, -6, 2, 12, 12, height_bricks=6, axis="X", mat_name="TAN")
    # Brown timber corner columns (2x2 studs)
    add_single_brick(-6, -6, 2, 2, 2, height_plates=18, mat_name="BROWN", studs=False)
    add_single_brick(4, -6, 2, 2, 2, height_plates=18, mat_name="BROWN", studs=False)
    add_single_brick(-6, 4, 2, 2, 2, height_plates=18, mat_name="BROWN", studs=False)
    add_single_brick(4, 4, 2, 2, 2, height_plates=18, mat_name="BROWN", studs=False)

    # Front Wooden Door Decal & Hanging Lantern
    add_decal_tile(0.0, -6 * U - 0.05, 10 * PLATE_H, 2.0, 2.2, "DECAL_DOOR", normal="-Y")
    add_cylinder_brick(3.5, -6.3, 14, radius_studs=0.5, height_plates=4, mat_name="RED", stud=False)

    # Side Arched Window
    add_decal_tile(-6 * U - 0.05, 0.0, 11 * PLATE_H, 1.4, 1.4, "DECAL_WINDOW", normal="-X")

    # Brick Chimney climbing up right flank (44 plates tall)
    add_brick_wall(6, 0, 2, 2, 4, height_bricks=14, axis="Y", mat_name="DARK_RED")
    add_single_brick(6, 0, 44, 2, 4, height_plates=3, mat_name="DARK_GREY", studs=True)

    # Lower Pagoda Roof (Cantilevered Red Slope Bricks, 16x16 studs, z=20 to z=24)
    for x in range(-8, 8, 2):
        add_slope_brick(x, -8, 20, 2, 2, slope_dir="-Y", height_plates=4, mat_name="RED")
        add_slope_brick(x, 6, 20, 2, 2, slope_dir="+Y", height_plates=4, mat_name="RED")
    for y in range(-6, 6, 2):
        add_slope_brick(-8, y, 20, 2, 2, slope_dir="-X", height_plates=4, mat_name="RED")
        add_slope_brick(6, y, 20, 2, 2, slope_dir="+X", height_plates=4, mat_name="RED")

    # Upper Pavilion (8x8 studs, z=24 to z=36 = 4 bricks tall)
    add_brick_wall(-4, -4, 24, 8, 8, height_bricks=4, axis="X", mat_name="TAN")
    add_single_brick(-4, -4, 24, 2, 2, height_plates=12, mat_name="BROWN", studs=False)
    add_single_brick(2, -4, 24, 2, 2, height_plates=12, mat_name="BROWN", studs=False)
    add_single_brick(-4, 2, 24, 2, 2, height_plates=12, mat_name="BROWN", studs=False)
    add_single_brick(2, 2, 24, 2, 2, height_plates=12, mat_name="BROWN", studs=False)
    # Upper window
    add_decal_tile(0.0, -4 * U - 0.05, 30 * PLATE_H, 1.3, 1.3, "DECAL_WINDOW", normal="-Y")

    # Top Pagoda Roof (12x12 red slope roof, z=36 to z=42)
    for x in range(-6, 6, 2):
        add_slope_brick(x, -6, 36, 2, 2, slope_dir="-Y", height_plates=4, mat_name="RED")
        add_slope_brick(x, 4, 36, 2, 2, slope_dir="+Y", height_plates=4, mat_name="RED")
    for y in range(-4, 4, 2):
        add_slope_brick(-6, y, 36, 2, 2, slope_dir="-X", height_plates=4, mat_name="RED")
        add_slope_brick(4, y, 36, 2, 2, slope_dir="+X", height_plates=4, mat_name="RED")

    # Golden Roof Spire Finial
    add_single_brick(-2, -2, 42, 4, 4, height_plates=2, mat_name="GOLD", studs=True)
    add_cone(0.0, 0.0, 44 * PLATE_H, 0.40, 1.8, "GOLD")

    export_scene(output_path, target_height=5.5)

# =========================================================================
# 3. LEGO MILITARY BARRACKS (50% Smaller Bricks)
# =========================================================================
def build_lego_barracks(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Foundation (20x16 studs)
    add_single_brick(-10, -8, 0, 20, 16, height_plates=2, mat_name="DARK_GREY", studs=True)

    # Reddish Brown Timber Log Walls (16x12 studs, 6 bricks tall)
    add_brick_wall(-8, -6, 2, 16, 12, height_bricks=6, axis="X", mat_name="BROWN")
    # Corner dark log posts (2x2 studs)
    for z in range(2, 20, 6):
        add_single_brick(-8, -6, z, 2, 2, height_plates=6, mat_name="DARK_BROWN", studs=False)
        add_single_brick(6, -6, z, 2, 2, height_plates=6, mat_name="DARK_BROWN", studs=False)
        add_single_brick(-8, 4, z, 2, 2, height_plates=6, mat_name="DARK_BROWN", studs=False)
        add_single_brick(6, 4, z, 2, 2, height_plates=6, mat_name="DARK_BROWN", studs=False)

    # Archery Training Dummy with Target Decal
    add_cylinder_brick(5.0, -7.5, 2, radius_studs=0.5, height_plates=9, mat_name="BROWN", stud=False)
    add_decal_tile(6.0 * U, -7.5 * U - 0.05, 9 * PLATE_H, 1.4, 1.4, "DECAL_TARGET", normal="-Y")

    # Front Entrance Door Decal & Dragon Shield
    add_decal_tile(-2.0 * U, -6 * U - 0.05, 9 * PLATE_H, 2.0, 2.2, "DECAL_DOOR", normal="-Y")
    add_decal_tile(-6.0 * U, -6 * U - 0.05, 11 * PLATE_H, 1.4, 1.4, "DECAL_SHIELD", normal="-Y")

    # Dark Red & Red Slope Roof (20x16 studs, z=20 to z=30)
    for x in range(-10, 10, 2):
        add_slope_brick(x, -8, 20, 2, 2, slope_dir="-Y", height_plates=4, mat_name="DARK_RED")
        add_slope_brick(x, 6, 20, 2, 2, slope_dir="+Y", height_plates=4, mat_name="DARK_RED")
    # Central Ridge Beam
    add_single_brick(-8, -2, 26, 16, 4, height_plates=4, mat_name="RED", studs=True)

    # Observation Loft & Banner Flagpole
    add_crenellation(-2, -2, 30, 4, 4, mat_name="STONE_GREY")
    add_cylinder_brick(0, 0, 34, radius_studs=0.2, height_plates=10, mat_name="GOLD", stud=False)
    add_single_brick(0, 0, 40, 4, 1, height_plates=4, mat_name="RED", studs=False)

    export_scene(output_path, target_height=6.0)

# =========================================================================
# 4. LEGO GUARD WATCHTOWER (50% Smaller Bricks)
# =========================================================================
def build_lego_tower(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Base (12x12 studs)
    add_single_brick(-6, -6, 0, 12, 12, height_plates=2, mat_name="DARK_GREY", studs=True)

    # Tower Shaft: 8x8 studs rising 14 bricks tall (42 plates!)
    add_brick_wall(-4, -4, 2, 8, 8, height_bricks=14, axis="X", mat_name="STONE_GREY")
    # Dark grey corner quoin stones (2x2 studs)
    for z in range(2, 42, 12):
        add_single_brick(-4, -4, z, 2, 2, height_plates=6, mat_name="DARK_GREY", studs=False)
        add_single_brick(2, -4, z, 2, 2, height_plates=6, mat_name="DARK_GREY", studs=False)
        add_single_brick(-4, 2, z, 2, 2, height_plates=6, mat_name="DARK_GREY", studs=False)
        add_single_brick(2, 2, z, 2, 2, height_plates=6, mat_name="DARK_GREY", studs=False)

    # Front Arched Arrow Slit Window & Shield
    add_decal_tile(0.0, -4 * U - 0.05, 24 * PLATE_H, 1.4, 1.4, "DECAL_WINDOW", normal="-Y")
    add_decal_tile(0.0, -4 * U - 0.05, 12 * PLATE_H, 1.3, 1.3, "DECAL_SHIELD", normal="-Y")

    # Overhanging Corbel Plate (12x12 studs, z=44)
    add_single_brick(-6, -6, 44, 12, 12, height_plates=2, mat_name="DARK_GREY", studs=False)

    # 360-Degree Battlement Parapet with Crenellations (12x12 studs, z=46)
    add_crenellation(-6, -6, 46, 12, 12, mat_name="STONE_GREY")

    # Signal Fire Brazier with vibrant Trans-Orange Flame Piece
    add_cylinder_brick(-1, -1, 46, radius_studs=1.2, height_plates=4, mat_name="DARK_GREY", stud=False)
    add_cone(0.0, 0.0, 50 * PLATE_H, 0.45, 1.8, "FLAME")

    export_scene(output_path, target_height=7.5)

# =========================================================================
# 5. LEGO NATURE ASSETS (50% Smaller Bricks)
# =========================================================================
def build_lego_tree(output_path: str):
    reset_scene()
    init_materials()

    # Brown Trunk (cylinder bricks)
    add_cylinder_brick(-1, -1, 0, radius_studs=0.8, height_plates=8, mat_name="BROWN", stud=False)

    # 6 Tiered Faceted Foliage Plates with Studs (Classic LEGO Pine Tree!)
    # Tier 1 (12x12 studs green base)
    add_single_brick(-6, -6, 8, 12, 12, height_plates=3, mat_name="GREEN", studs=True)
    # Tier 2 (10x10 studs)
    add_single_brick(-5, -5, 11, 10, 10, height_plates=3, mat_name="GREEN", studs=True)
    # Tier 3 (8x8 studs bright green / lime highlight)
    add_single_brick(-4, -4, 14, 8, 8, height_plates=3, mat_name="LIME", studs=True)
    # Tier 4 (6x6 studs)
    add_single_brick(-3, -3, 17, 6, 6, height_plates=3, mat_name="GREEN", studs=True)
    # Tier 5 (4x4 studs lime)
    add_single_brick(-2, -2, 20, 4, 4, height_plates=3, mat_name="LIME", studs=True)
    # Tier 6 (2x2 studs green peak)
    add_single_brick(-1, -1, 23, 2, 2, height_plates=2, mat_name="GREEN", studs=True)
    # Top Pine Cone Spire
    add_cone(0.0, 0.0, 25 * PLATE_H, 0.50, 1.8, "GREEN")

    export_scene(output_path, target_height=3.6)

def build_lego_stone(output_path: str):
    reset_scene()
    init_materials()

    # Chunky Faceted Boulder made of slope bricks and plates (8x8 studs)
    add_single_brick(-4, -4, 0, 8, 8, height_plates=2, mat_name="DARK_GREY", studs=True)
    add_slope_brick(-4, -4, 2, 4, 4, slope_dir="-Y", height_plates=5, mat_name="STONE_GREY")
    add_slope_brick(0, -4, 2, 4, 4, slope_dir="+X", height_plates=5, mat_name="DARK_GREY")
    add_slope_brick(-4, 0, 2, 4, 4, slope_dir="-X", height_plates=5, mat_name="DARK_GREY")
    add_slope_brick(0, 0, 2, 4, 4, slope_dir="+Y", height_plates=5, mat_name="STONE_GREY")
    add_single_brick(-2, -2, 7, 4, 4, height_plates=3, mat_name="STONE_GREY", studs=True)

    export_scene(output_path, target_height=1.8)

def build_lego_gold(output_path: str):
    reset_scene()
    init_materials()

    # Dark stone rock vein (8x8 studs)
    add_single_brick(-4, -4, 0, 8, 8, height_plates=2, mat_name="DARK_GREY", studs=True)
    add_slope_brick(-4, -4, 2, 4, 4, slope_dir="-Y", height_plates=5, mat_name="DARK_GREY")
    add_slope_brick(0, 0, 2, 4, 4, slope_dir="+Y", height_plates=5, mat_name="DARK_GREY")

    # Sparkling Pearl Gold Bricks, Studs, and Crystal Cone
    add_single_brick(-2, -2, 2, 4, 4, height_plates=5, mat_name="GOLD", studs=True)
    add_cylinder_brick(0.5, -1.5, 7, radius_studs=0.6, height_plates=3, mat_name="GOLD", stud=True)
    add_cylinder_brick(-1.5, 0.5, 7, radius_studs=0.6, height_plates=3, mat_name="GOLD", stud=True)
    add_cone(0.0, 0.0, 10 * PLATE_H, 0.45, 1.2, "GOLD")

    export_scene(output_path, target_height=1.6)

def build_lego_berry_bush(output_path: str):
    reset_scene()
    init_materials()

    # Green leaf plates (8x8 studs)
    add_single_brick(-4, -4, 0, 8, 8, height_plates=3, mat_name="GREEN", studs=True)
    add_single_brick(-2, -2, 3, 4, 4, height_plates=3, mat_name="LIME", studs=True)

    # Bright Red 1x1 Round Stud Berries
    berry_coords = [
        (-2.5, -2.5, 3), (2.5, -2.5, 3), (-2.5, 2.5, 3), (2.5, 2.5, 3),
        (-1.0, 1.0, 6), (1.0, -1.0, 6), (0.0, 0.0, 6),
        (-2.0, 0.0, 3), (2.0, 0.0, 3), (0.0, -2.0, 3), (0.0, 2.0, 3)
    ]
    for bx, by, bz in berry_coords:
        add_cylinder_brick(bx, by, bz, radius_studs=0.4, height_plates=2, mat_name="RED", stud=True)

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

    bpy.context.view_layer.objects.active = selected_objs[0]
    bpy.ops.object.join()
    unified_obj = bpy.context.active_object
    unified_obj.name = "LegoModel"

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
    print("      MICRO-LEGO ARCHITECTURE ASSEMBLER ")
    print("========================================")

    models_dir = "/Users/cuong.le/Document/build-the-game/assets/models"

    if target in ["all", "town_center"]:
        print("Assembling 50% Finer LEGO Imperial Town Center...")
        build_lego_town_center(f"{models_dir}/pixel_town_center.glb")

    if target in ["all", "house"]:
        print("Assembling 50% Finer LEGO Pagoda House...")
        build_lego_house(f"{models_dir}/pixel_house.glb")

    if target in ["all", "barracks"]:
        print("Assembling 50% Finer LEGO Barracks...")
        build_lego_barracks(f"{models_dir}/pixel_barracks.glb")

    if target in ["all", "tower"]:
        print("Assembling 50% Finer LEGO Guard Watchtower...")
        build_lego_tower(f"{models_dir}/pixel_tower.glb")
        os.system(f"cp {models_dir}/pixel_tower.glb {models_dir}/pixel_guard_tower.glb")

    if target in ["all", "nature", "tree"]:
        print("Assembling 50% Finer LEGO Pine Tree...")
        build_lego_tree(f"{models_dir}/pixel_tree.glb")

    if target in ["all", "nature", "stone"]:
        print("Assembling 50% Finer LEGO Boulder...")
        build_lego_stone(f"{models_dir}/pixel_stone.glb")

    if target in ["all", "nature", "gold"]:
        print("Assembling 50% Finer LEGO Gold Vein...")
        build_lego_gold(f"{models_dir}/pixel_gold.glb")

    if target in ["all", "nature", "food"]:
        print("Assembling 50% Finer LEGO Berry Bush...")
        build_lego_berry_bush(f"{models_dir}/pixel_food.glb")

    print("\nAll 50% finer LEGO assemblies generated successfully!")
