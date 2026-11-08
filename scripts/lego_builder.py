#!/usr/bin/env python3
"""
lego_builder.py
High-Fidelity LEGO Architectural & Modular Kit Assembler for Island Empire.
Features:
- 80% Further Reduced Brick Size (Micro-LEGO / Nanoblock Precision Scale: U=0.08m)
  -> 5x more blocks per axis, 125x more individual blocks per structure!
- Wide variety of vibrant, colorful designs generated via PixelLab MCP:
  * Azure glazed dragon roof tiles (pattern_roof_azure.png)
  * Imperial gold filigree frieze reliefs (pattern_gold_frieze.png)
  * Stained glass rose mosaic windows (pattern_stained_glass.png)
  * Ancient Nordic rune stone masonry (pattern_rune_stone.png)
  * Vermilion lacquered wood timbers (pattern_crimson_wood.png)
  * Royal dragon crest shields, wooden gates, archery targets
- Scenic Ancient Monolith Landmark model (scenic_monolith.glb)
"""

import sys
import os
import math
import bpy
import mathutils

# LEGO Ultra-Fine Scale Dimensions (Reduced by 80% from 0.4m -> 0.08m)
U = 0.08
PLATE_H = 0.032
BRICK_H = PLATE_H * 3.0
STUD_R = 0.022
STUD_H = 0.014
SEAM = 0.0018

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

def create_textured_material(name: str, texture_path: str, roughness: float = 0.22, emission_mult: float = 0.0) -> bpy.types.Material:
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
            bsdf.inputs["Roughness"].default_value = roughness
            if emission_mult > 0.0:
                links.new(tex_node.outputs["Color"], bsdf.inputs["Emission Color"])
                if "Emission Strength" in bsdf.inputs:
                    bsdf.inputs["Emission Strength"].default_value = emission_mult
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
    MATERIALS["GOLD"] = create_lego_material("Mat_Gold", (0.95, 0.76, 0.14, 1.0), roughness=0.18, metallic=0.45)
    MATERIALS["BLUE"] = create_lego_material("Mat_Blue", (0.08, 0.30, 0.72, 1.0), roughness=0.24)
    MATERIALS["CYAN"] = create_lego_material("Mat_Cyan", (0.12, 0.65, 0.88, 1.0), roughness=0.20)
    MATERIALS["GREEN"] = create_lego_material("Mat_Green", (0.10, 0.45, 0.15, 1.0), roughness=0.25)
    MATERIALS["LIME"] = create_lego_material("Mat_Lime", (0.35, 0.68, 0.18, 1.0), roughness=0.25)
    MATERIALS["FLAME"] = create_lego_material("Mat_Flame", (1.0, 0.5, 0.05, 1.0), roughness=0.10, emission=(1.0, 0.45, 0.05, 1.0))

    # Vibrant MCP Texture Designs
    lego_dir = "/Users/cuong.le/Document/build-the-game/assets/lego"
    MATERIALS["TEX_ROOF_AZURE"] = create_textured_material("Mat_RoofAzure", f"{lego_dir}/pattern_roof_azure.png", roughness=0.18)
    MATERIALS["TEX_GOLD_FRIEZE"] = create_textured_material("Mat_GoldFrieze", f"{lego_dir}/pattern_gold_frieze.png", roughness=0.20)
    MATERIALS["TEX_STAINED_GLASS"] = create_textured_material("Mat_StainedGlass", f"{lego_dir}/pattern_stained_glass.png", roughness=0.15, emission_mult=1.8)
    MATERIALS["TEX_RUNE_STONE"] = create_textured_material("Mat_RuneStone", f"{lego_dir}/pattern_rune_stone.png", roughness=0.30)
    MATERIALS["TEX_CRIMSON_WOOD"] = create_textured_material("Mat_CrimsonWood", f"{lego_dir}/pattern_crimson_wood.png", roughness=0.25)

    # Decals
    MATERIALS["DECAL_DOOR"] = create_textured_material("Mat_DecalDoor", f"{lego_dir}/decal_door.png")
    MATERIALS["DECAL_SHIELD"] = create_textured_material("Mat_DecalShield", f"{lego_dir}/decal_shield.png")
    MATERIALS["DECAL_WINDOW"] = create_textured_material("Mat_DecalWindow", f"{lego_dir}/decal_window.png")
    MATERIALS["DECAL_TARGET"] = create_textured_material("Mat_DecalTarget", f"{lego_dir}/decal_target.png")

# Geometry Helpers
def add_stud(x: float, y: float, z: float, mat_name: str = "STONE_GREY"):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=8,
        radius=STUD_R,
        depth=STUD_H,
        location=(x, y, z + STUD_H / 2.0)
    )
    obj = bpy.context.active_object
    obj.data.materials.append(MATERIALS[mat_name])
    return obj

def add_single_brick(gx: float, gy: float, gz_plates: int, studs_x: int, studs_y: int, height_plates: int = 3, mat_name: str = "STONE_GREY", studs: bool = True, stud_step: int = 2):
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
        for ix in range(0, studs_x, stud_step):
            for iy in range(0, studs_y, stud_step):
                sx = gx * U + (ix + 0.5) * U
                sy = gy * U + (iy + 0.5) * U
                add_stud(sx, sy, top_z, mat_name)
    return obj

def add_brick_wall(start_gx: int, start_gy: int, start_gz_plates: int, studs_length: int, thickness_studs: int, height_bricks: int, axis: str = "X", mat_name: str = "STONE_GREY", studs: bool = False):
    """Generates fine masonry wall with staggered courses."""
    for b_idx in range(height_bricks):
        cur_z = start_gz_plates + b_idx * 3
        is_top = (b_idx == height_bricks - 1) and studs
        offset = (b_idx % 2) * 4 # 4-stud stagger

        pos = 0
        while pos < studs_length:
            remaining = studs_length - pos
            if pos == 0 and offset == 4 and remaining > 4:
                cur_len = 4
            elif remaining >= 8:
                cur_len = 8
            elif remaining >= 4:
                cur_len = 4
            else:
                cur_len = remaining

            if axis == "X":
                add_single_brick(start_gx + pos, start_gy, cur_z, cur_len, thickness_studs, height_plates=3, mat_name=mat_name, studs=is_top, stud_step=2)
            else:
                add_single_brick(start_gx, start_gy + pos, cur_z, thickness_studs, cur_len, height_plates=3, mat_name=mat_name, studs=is_top, stud_step=2)
            pos += cur_len

def add_slope_brick(gx: float, gy: float, gz_plates: int, studs_x: int, studs_y: int, slope_dir: str = "+Y", height_plates: int = 3, mat_name: str = "RED"):
    w = studs_x * U - SEAM
    l = studs_y * U - SEAM
    h = height_plates * PLATE_H - SEAM * 0.5
    x0 = gx * U + SEAM * 0.5
    y0 = gy * U + SEAM * 0.5
    z0 = gz_plates * PLATE_H

    verts = [
        (x0, y0, z0),
        (x0 + w, y0, z0),
        (x0 + w, y0 + l, z0),
        (x0, y0 + l, z0),
    ]

    if slope_dir == "+Y":
        verts.extend([
            (x0, y0, z0 + h),
            (x0 + w, y0, z0 + h),
            (x0 + w, y0 + l, z0),
            (x0, y0 + l, z0),
        ])
    elif slope_dir == "-Y":
        verts.extend([
            (x0, y0, z0),
            (x0 + w, y0, z0),
            (x0 + w, y0 + l, z0 + h),
            (x0, y0 + l, z0 + h),
        ])
    elif slope_dir == "+X":
        verts.extend([
            (x0, y0, z0 + h),
            (x0 + w, y0, z0),
            (x0 + w, y0 + l, z0),
            (x0, y0 + l, z0 + h),
        ])
    else:
        verts.extend([
            (x0, y0, z0),
            (x0 + w, y0, z0 + h),
            (x0 + w, y0 + l, z0 + h),
            (x0, y0 + l, z0),
        ])

    faces = [
        (0, 1, 2, 3),
        (4, 5, 6, 7),
        (0, 4, 7, 3),
        (1, 2, 6, 5),
        (0, 1, 5, 4),
        (3, 7, 6, 2),
    ]

    mesh = bpy.data.meshes.new("SlopeMesh")
    obj = bpy.data.objects.new("SlopeObj", mesh)
    bpy.context.collection.objects.link(obj)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.data.materials.append(MATERIALS[mat_name])
    return obj

def add_crenellation(gx: float, gy: float, gz_plates: int, studs_x: int, studs_y: int, mat_name: str = "STONE_GREY"):
    add_single_brick(gx, gy, gz_plates, studs_x, studs_y, height_plates=1, mat_name="DARK_GREY", studs=False)
    step = 4
    for ix in range(0, studs_x, step):
        for iy in range(0, studs_y, step):
            is_edge = (ix == 0 or ix >= studs_x - step or iy == 0 or iy >= studs_y - step)
            if is_edge:
                add_single_brick(gx + ix, gy + iy, gz_plates + 1, 2, 2, height_plates=2, mat_name=mat_name, studs=True, stud_step=1)

def add_cylinder_brick(gx: float, gy: float, gz_plates: int, radius_studs: float = 2.0, height_plates: int = 3, mat_name: str = "BROWN", stud: bool = True):
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
# 1. LEGO IMPERIAL TOWN CENTER / CASTLE KEEP (80% Smaller Micro-LEGO Scale)
# =========================================================================
def build_lego_town_center(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Foundation (70x60 studs at U=0.08m)
    add_single_brick(-35, -30, 0, 70, 60, height_plates=3, mat_name="DARK_GREY", studs=True, stud_step=4)

    # 4 Corner Watchtower Bastions (15x15 studs each, 25 bricks tall = 75 plates)
    towers = [(-30, -25), (15, -25), (-30, 10), (15, 10)]
    for tx, ty in towers:
        # Carved Ancient Rune Stone Masonry Walls
        add_brick_wall(tx, ty, 3, 15, 15, height_bricks=25, axis="X", mat_name="TEX_RUNE_STONE")
        # Overhanging battlement deck with crenellations (19x19 studs)
        add_crenellation(tx - 2, ty - 2, 78, 19, 19, mat_name="STONE_GREY")
        # Golden corner spire finials
        add_cone((tx + 7.5) * U, (ty + 7.5) * U, 88 * PLATE_H, 0.45, 1.6, "GOLD")

    # Curtain Walls (Connecting towers to gatehouse)
    add_brick_wall(-15, -25, 3, 10, 10, height_bricks=15, axis="X", mat_name="STONE_GREY")
    add_brick_wall(5, -25, 3, 10, 10, height_bricks=15, axis="X", mat_name="STONE_GREY")
    add_crenellation(-15, -25, 48, 10, 10, mat_name="STONE_GREY")
    add_crenellation(5, -25, 48, 10, 10, mat_name="STONE_GREY")

    # Ornate Imperial Golden Frieze Belt
    add_single_brick(-30, -26, 42, 60, 2, height_plates=3, mat_name="TEX_GOLD_FRIEZE", studs=False)

    # Front Gatehouse Arch
    add_single_brick(-5, -25, 3, 10, 10, height_plates=12, mat_name="DARK_GREY", studs=False)
    add_single_brick(-5, -25, 36, 10, 10, height_plates=12, mat_name="STONE_GREY", studs=False)
    # Printed Double Wooden Gate Decal
    add_decal_tile(0.0, -25 * U - 0.06, 22 * PLATE_H, 2.8, 3.0, "DECAL_DOOR", normal="-Y")
    # Royal Dragon Shield Crest mounted proudly above the gate
    add_decal_tile(0.0, -25 * U - 0.08, 45 * PLATE_H, 1.6, 1.6, "DECAL_SHIELD", normal="-Y")

    # MAIN KEEP - Level 1: Stone Great Hall (40x30 studs, z=3 to z=60 = 19 bricks tall)
    add_brick_wall(-20, -15, 3, 40, 30, height_bricks=19, axis="X", mat_name="STONE_GREY")
    # Front Stained Glass Rose Windows (Vibrant Mosaic Glowing Panes)
    add_decal_tile(-10.0 * U, -15 * U - 0.05, 30 * PLATE_H, 1.8, 1.8, "TEX_STAINED_GLASS", normal="-Y")
    add_decal_tile(10.0 * U, -15 * U - 0.05, 30 * PLATE_H, 1.8, 1.8, "TEX_STAINED_GLASS", normal="-Y")
    add_decal_tile(-20 * U - 0.05, 0.0, 30 * PLATE_H, 1.8, 1.8, "TEX_STAINED_GLASS", normal="-X")
    add_decal_tile(20 * U + 0.05, 0.0, 30 * PLATE_H, 1.8, 1.8, "TEX_STAINED_GLASS", normal="+X")

    # Pagoda Eaves Level 1: Vibrant Azure Glazed Dragon Roof Tiles (50x40 studs, z=60 to z=68)
    for x in range(-25, 25, 5):
        add_slope_brick(x, -20, 60, 5, 5, slope_dir="-Y", height_plates=8, mat_name="TEX_ROOF_AZURE")
        add_slope_brick(x, 15, 60, 5, 5, slope_dir="+Y", height_plates=8, mat_name="TEX_ROOF_AZURE")
    for y in range(-15, 15, 5):
        add_slope_brick(-25, y, 60, 5, 5, slope_dir="-X", height_plates=8, mat_name="TEX_ROOF_AZURE")
        add_slope_brick(20, y, 60, 5, 5, slope_dir="+X", height_plates=8, mat_name="TEX_ROOF_AZURE")

    # Level 2: Imperial Pavilion (Vermilion Lacquer Wood & Golden Inlays, 30x20 studs, z=68 to z=110)
    add_brick_wall(-15, -10, 68, 30, 20, height_bricks=14, axis="X", mat_name="TEX_CRIMSON_WOOD")
    # Corner Golden Frieze Columns
    add_single_brick(-15, -10, 68, 4, 4, height_plates=42, mat_name="TEX_GOLD_FRIEZE", studs=False)
    add_single_brick(11, -10, 68, 4, 4, height_plates=42, mat_name="TEX_GOLD_FRIEZE", studs=False)
    add_single_brick(-15, 6, 68, 4, 4, height_plates=42, mat_name="TEX_GOLD_FRIEZE", studs=False)
    add_single_brick(11, 6, 68, 4, 4, height_plates=42, mat_name="TEX_GOLD_FRIEZE", studs=False)
    # Pavilion front stained glass window
    add_decal_tile(0.0, -10 * U - 0.05, 88 * PLATE_H, 1.8, 1.8, "TEX_STAINED_GLASS", normal="-Y")

    # Pagoda Eaves Level 2: Azure Glazed Tiles (40x30 studs, z=110 to z=118)
    for x in range(-20, 20, 5):
        add_slope_brick(x, -15, 110, 5, 5, slope_dir="-Y", height_plates=8, mat_name="TEX_ROOF_AZURE")
        add_slope_brick(x, 10, 110, 5, 5, slope_dir="+Y", height_plates=8, mat_name="TEX_ROOF_AZURE")
    for y in range(-10, 10, 5):
        add_slope_brick(-20, y, 110, 5, 5, slope_dir="-X", height_plates=8, mat_name="TEX_ROOF_AZURE")
        add_slope_brick(15, y, 110, 5, 5, slope_dir="+X", height_plates=8, mat_name="TEX_ROOF_AZURE")

    # Level 3: Golden Observation Pavilion (20x10 studs, z=118 to z=142)
    add_single_brick(-10, -5, 118, 20, 10, height_plates=24, mat_name="WHITE", studs=False)
    # Golden columns
    add_cylinder_brick(-8, -4, 118, radius_studs=1.5, height_plates=24, mat_name="GOLD", stud=False)
    add_cylinder_brick(5, -4, 118, radius_studs=1.5, height_plates=24, mat_name="GOLD", stud=False)
    add_cylinder_brick(-8, 1, 118, radius_studs=1.5, height_plates=24, mat_name="GOLD", stud=False)
    add_cylinder_brick(5, 1, 118, radius_studs=1.5, height_plates=24, mat_name="GOLD", stud=False)

    # Top Roof: Bright Red and Azure Peak (30x20 studs, z=142 to z=158)
    for x in range(-15, 15, 5):
        add_slope_brick(x, -10, 142, 5, 5, slope_dir="-Y", height_plates=8, mat_name="RED")
        add_slope_brick(x, 5, 142, 5, 5, slope_dir="+Y", height_plates=8, mat_name="RED")
    # Golden Crown Ridge and Spire
    add_single_brick(-5, -5, 158, 10, 10, height_plates=6, mat_name="GOLD", studs=True, stud_step=2)
    add_cone(0.0, 0.0, 164 * PLATE_H, 0.55, 2.5, "GOLD")
    # Royal Red Pennant Flag
    add_single_brick(0, 0, 180, 8, 2, height_plates=8, mat_name="RED", studs=False)

    export_scene(output_path, target_height=9.0)

# =========================================================================
# 2. LEGO PAGODA COTTAGE / HOUSE (80% Smaller Micro-LEGO Scale)
# =========================================================================
def build_lego_house(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Foundation (40x40 studs)
    add_single_brick(-20, -20, 0, 40, 40, height_plates=3, mat_name="DARK_GREY", studs=True, stud_step=4)

    # Ground Floor: Warm Tan Masonry Walls (30x30 studs, z=3 to z=45 = 14 bricks tall)
    add_brick_wall(-15, -15, 3, 30, 30, height_bricks=14, axis="X", mat_name="TAN")
    # Vermilion crimson corner columns (4x4 studs)
    add_single_brick(-15, -15, 3, 4, 4, height_plates=42, mat_name="TEX_CRIMSON_WOOD", studs=False)
    add_single_brick(11, -15, 3, 4, 4, height_plates=42, mat_name="TEX_CRIMSON_WOOD", studs=False)
    add_single_brick(-15, 11, 3, 4, 4, height_plates=42, mat_name="TEX_CRIMSON_WOOD", studs=False)
    add_single_brick(11, 11, 3, 4, 4, height_plates=42, mat_name="TEX_CRIMSON_WOOD", studs=False)

    # Front Wooden Door Decal & Lantern
    add_decal_tile(0.0, -15 * U - 0.05, 22 * PLATE_H, 2.2, 2.4, "DECAL_DOOR", normal="-Y")
    add_cylinder_brick(8.0, -15.5, 30, radius_studs=1.2, height_plates=8, mat_name="RED", stud=False)

    # Side Stained Glass Window
    add_decal_tile(-15 * U - 0.05, 0.0, 24 * PLATE_H, 1.6, 1.6, "TEX_STAINED_GLASS", normal="-X")

    # Dark Red Brick Chimney (100 plates tall)
    add_brick_wall(15, 0, 3, 4, 8, height_bricks=32, axis="Y", mat_name="DARK_RED")
    add_single_brick(15, 0, 99, 4, 8, height_plates=6, mat_name="DARK_GREY", studs=True, stud_step=2)

    # Lower Pagoda Roof: Vibrant Azure & Red Tiles (40x40 studs, z=45 to z=55)
    for x in range(-20, 20, 5):
        add_slope_brick(x, -20, 45, 5, 5, slope_dir="-Y", height_plates=8, mat_name="TEX_ROOF_AZURE")
        add_slope_brick(x, 15, 45, 5, 5, slope_dir="+Y", height_plates=8, mat_name="TEX_ROOF_AZURE")
    for y in range(-15, 15, 5):
        add_slope_brick(-20, y, 45, 5, 5, slope_dir="-X", height_plates=8, mat_name="TEX_ROOF_AZURE")
        add_slope_brick(15, y, 45, 5, 5, slope_dir="+X", height_plates=8, mat_name="TEX_ROOF_AZURE")

    # Upper Pavilion (20x20 studs, z=55 to z=85)
    add_brick_wall(-10, -10, 55, 20, 20, height_bricks=10, axis="X", mat_name="TAN")
    add_single_brick(-10, -10, 55, 4, 4, height_plates=30, mat_name="TEX_CRIMSON_WOOD", studs=False)
    add_single_brick(6, -10, 55, 4, 4, height_plates=30, mat_name="TEX_CRIMSON_WOOD", studs=False)
    add_single_brick(-10, 6, 55, 4, 4, height_plates=30, mat_name="TEX_CRIMSON_WOOD", studs=False)
    add_single_brick(6, 6, 55, 4, 4, height_plates=30, mat_name="TEX_CRIMSON_WOOD", studs=False)
    # Upper window
    add_decal_tile(0.0, -10 * U - 0.05, 70 * PLATE_H, 1.5, 1.5, "DECAL_WINDOW", normal="-Y")

    # Top Pagoda Roof (30x30 studs, z=85 to z=98)
    for x in range(-15, 15, 5):
        add_slope_brick(x, -15, 85, 5, 5, slope_dir="-Y", height_plates=8, mat_name="RED")
        add_slope_brick(x, 10, 85, 5, 5, slope_dir="+Y", height_plates=8, mat_name="RED")
    for y in range(-10, 10, 5):
        add_slope_brick(-15, y, 85, 5, 5, slope_dir="-X", height_plates=8, mat_name="RED")
        add_slope_brick(10, y, 85, 5, 5, slope_dir="+X", height_plates=8, mat_name="RED")

    # Golden Roof Spire Finial
    add_single_brick(-4, -4, 98, 8, 8, height_plates=4, mat_name="GOLD", studs=True, stud_step=2)
    add_cone(0.0, 0.0, 102 * PLATE_H, 0.45, 2.0, "GOLD")

    export_scene(output_path, target_height=5.5)

# =========================================================================
# 3. LEGO MILITARY BARRACKS (80% Smaller Micro-LEGO Scale)
# =========================================================================
def build_lego_barracks(output_path: str):
    reset_scene()
    init_materials()

    # Foundation (50x40 studs)
    add_single_brick(-25, -20, 0, 50, 40, height_plates=3, mat_name="DARK_GREY", studs=True, stud_step=4)

    # Reddish Brown Timber Log Walls (40x30 studs, 14 bricks tall)
    add_brick_wall(-20, -15, 3, 40, 30, height_bricks=14, axis="X", mat_name="BROWN")
    # Corner dark log posts (4x4 studs)
    for z in range(3, 45, 12):
        add_single_brick(-20, -15, z, 4, 4, height_plates=12, mat_name="DARK_BROWN", studs=False)
        add_single_brick(16, -15, z, 4, 4, height_plates=12, mat_name="DARK_BROWN", studs=False)
        add_single_brick(-20, 11, z, 4, 4, height_plates=12, mat_name="DARK_BROWN", studs=False)
        add_single_brick(16, 11, z, 4, 4, height_plates=12, mat_name="DARK_BROWN", studs=False)

    # Archery Training Dummy with Target Decal
    add_cylinder_brick(12.0, -18.0, 3, radius_studs=1.2, height_plates=20, mat_name="BROWN", stud=False)
    add_decal_tile(15.0 * U, -18.0 * U - 0.05, 22 * PLATE_H, 1.6, 1.6, "DECAL_TARGET", normal="-Y")

    # Front Entrance Door Decal & Dragon Shield
    add_decal_tile(-5.0 * U, -15 * U - 0.05, 22 * PLATE_H, 2.2, 2.4, "DECAL_DOOR", normal="-Y")
    add_decal_tile(-15.0 * U, -15 * U - 0.05, 26 * PLATE_H, 1.6, 1.6, "DECAL_SHIELD", normal="-Y")

    # Roof: Dark Red & Red Slope Roof (50x40 studs, z=45 to z=68)
    for x in range(-25, 25, 5):
        add_slope_brick(x, -20, 45, 5, 5, slope_dir="-Y", height_plates=8, mat_name="DARK_RED")
        add_slope_brick(x, 15, 45, 5, 5, slope_dir="+Y", height_plates=8, mat_name="DARK_RED")
    # Ridge Beam
    add_single_brick(-20, -4, 58, 40, 8, height_plates=8, mat_name="RED", studs=True, stud_step=2)

    # Observation Loft & Banner Flagpole
    add_crenellation(-5, -5, 68, 10, 10, mat_name="STONE_GREY")
    add_cylinder_brick(0, 0, 78, radius_studs=0.5, height_plates=24, mat_name="GOLD", stud=False)
    add_single_brick(0, 0, 92, 8, 2, height_plates=8, mat_name="RED", studs=False)

    export_scene(output_path, target_height=6.0)

# =========================================================================
# 4. LEGO GUARD WATCHTOWER (80% Smaller Micro-LEGO Scale)
# =========================================================================
def build_lego_tower(output_path: str):
    reset_scene()
    init_materials()

    # Dark Stone Base (30x30 studs)
    add_single_brick(-15, -15, 0, 30, 30, height_plates=3, mat_name="DARK_GREY", studs=True, stud_step=4)

    # Tower Shaft: 20x20 studs rising 32 bricks tall (96 plates!)
    # Ancient Rune Stone Masonry
    add_brick_wall(-10, -10, 3, 20, 20, height_bricks=32, axis="X", mat_name="TEX_RUNE_STONE")
    # Corner dark quoin stones
    for z in range(3, 96, 24):
        add_single_brick(-10, -10, z, 4, 4, height_plates=12, mat_name="DARK_GREY", studs=False)
        add_single_brick(6, -10, z, 4, 4, height_plates=12, mat_name="DARK_GREY", studs=False)
        add_single_brick(-10, 6, z, 4, 4, height_plates=12, mat_name="DARK_GREY", studs=False)
        add_single_brick(6, 6, z, 4, 4, height_plates=12, mat_name="DARK_GREY", studs=False)

    # Front Arched Arrow Slit Window & Shield
    add_decal_tile(0.0, -10 * U - 0.05, 54 * PLATE_H, 1.6, 1.6, "TEX_STAINED_GLASS", normal="-Y")
    add_decal_tile(0.0, -10 * U - 0.05, 26 * PLATE_H, 1.5, 1.5, "DECAL_SHIELD", normal="-Y")

    # Overhanging Corbel Plate (30x30 studs, z=99)
    add_single_brick(-15, -15, 99, 30, 30, height_plates=3, mat_name="DARK_GREY", studs=False)

    # 360-Degree Battlement Parapet with Crenellations (30x30 studs, z=102)
    add_crenellation(-15, -15, 102, 30, 30, mat_name="STONE_GREY")

    # Signal Fire Brazier with vibrant Trans-Orange Flame Piece
    add_cylinder_brick(-3, -3, 102, radius_studs=3.0, height_plates=8, mat_name="DARK_GREY", stud=False)
    add_cone(0.0, 0.0, 110 * PLATE_H, 0.50, 2.0, "FLAME")

    export_scene(output_path, target_height=7.5)

# =========================================================================
# 5. SCENIC ANCIENT MONOLITH LANDMARK
# =========================================================================
def build_scenic_monolith(output_path: str):
    reset_scene()
    init_materials()

    # Stepped Stone Plinth Base (24x24 studs, 3 tiers)
    add_single_brick(-12, -12, 0, 24, 24, height_plates=3, mat_name="DARK_GREY", studs=True, stud_step=2)
    add_single_brick(-9, -9, 3, 18, 18, height_plates=3, mat_name="TEX_RUNE_STONE", studs=True, stud_step=2)
    add_single_brick(-6, -6, 6, 12, 12, height_plates=3, mat_name="STONE_GREY", studs=True, stud_step=2)

    # 4 Corner Brazier Pylons with Golden Caps
    pylons = [(-11, -11), (9, -11), (-11, 9), (9, 9)]
    for px, py in pylons:
        add_single_brick(px, py, 3, 2, 2, height_plates=12, mat_name="TEX_RUNE_STONE", studs=False)
        add_cone((px + 1) * U, (py + 1) * U, 15 * PLATE_H, 0.25, 0.6, "GOLD")

    # Tapered Ancient Runic Obelisk Shaft (6x6 studs rising 60 plates tall)
    add_single_brick(-3, -3, 9, 6, 6, height_plates=30, mat_name="TEX_RUNE_STONE", studs=False)
    add_single_brick(-2, -2, 39, 4, 4, height_plates=30, mat_name="TEX_RUNE_STONE", studs=False)

    # Glowing Diamond Crystal Capstone (Bright Gold / Yellow Crystal)
    add_cone(0.0, 0.0, 69 * PLATE_H, 0.45, 1.8, "GOLD")

    export_scene(output_path, target_height=6.5)

# =========================================================================
# 6. LEGO NATURE ASSETS (80% Smaller Micro-LEGO Scale)
# =========================================================================
def build_lego_tree(output_path: str):
    reset_scene()
    init_materials()

    # Brown Trunk (cylinder bricks)
    add_cylinder_brick(-2, -2, 0, radius_studs=2.0, height_plates=18, mat_name="BROWN", stud=False)

    # 6 Tiered Faceted Foliage Plates with Studs (Classic LEGO Pine Tree!)
    tiers = [
        (30, 18, "GREEN"),
        (25, 24, "GREEN"),
        (20, 30, "LIME"),
        (15, 36, "GREEN"),
        (10, 42, "LIME"),
        (6, 48, "GREEN"),
    ]
    for size, z, col in tiers:
        half = size // 2
        add_single_brick(-half, -half, z, size, size, height_plates=4, mat_name=col, studs=True, stud_step=2)

    # Top Pine Cone Spire
    add_cone(0.0, 0.0, 52 * PLATE_H, 0.55, 2.0, "GREEN")

    export_scene(output_path, target_height=3.6)

def build_lego_stone(output_path: str):
    reset_scene()
    init_materials()

    # Faceted Boulder from slope bricks and plates (20x20 studs)
    add_single_brick(-10, -10, 0, 20, 20, height_plates=4, mat_name="DARK_GREY", studs=True, stud_step=2)
    add_slope_brick(-10, -10, 4, 10, 10, slope_dir="-Y", height_plates=10, mat_name="STONE_GREY")
    add_slope_brick(0, -10, 4, 10, 10, slope_dir="+X", height_plates=10, mat_name="DARK_GREY")
    add_slope_brick(-10, 0, 4, 10, 10, slope_dir="-X", height_plates=10, mat_name="DARK_GREY")
    add_slope_brick(0, 0, 4, 10, 10, slope_dir="+Y", height_plates=10, mat_name="STONE_GREY")
    add_single_brick(-5, -5, 14, 10, 10, height_plates=6, mat_name="STONE_GREY", studs=True, stud_step=2)

    export_scene(output_path, target_height=1.8)

def build_lego_gold(output_path: str):
    reset_scene()
    init_materials()

    # Dark stone rock vein (20x20 studs)
    add_single_brick(-10, -10, 0, 20, 20, height_plates=4, mat_name="DARK_GREY", studs=True, stud_step=2)
    add_slope_brick(-10, -10, 4, 10, 10, slope_dir="-Y", height_plates=10, mat_name="DARK_GREY")
    add_slope_brick(0, 0, 4, 10, 10, slope_dir="+Y", height_plates=10, mat_name="DARK_GREY")

    # Sparkling Pearl Gold Bricks, Studs, and Crystal Cone
    add_single_brick(-5, -5, 4, 10, 10, height_plates=10, mat_name="GOLD", studs=True, stud_step=1)
    add_cylinder_brick(1.5, -4.0, 14, radius_studs=1.5, height_plates=6, mat_name="GOLD", stud=True)
    add_cylinder_brick(-4.0, 1.5, 14, radius_studs=1.5, height_plates=6, mat_name="GOLD", stud=True)
    add_cone(0.0, 0.0, 20 * PLATE_H, 0.45, 1.4, "GOLD")

    export_scene(output_path, target_height=1.6)

def build_lego_berry_bush(output_path: str):
    reset_scene()
    init_materials()

    # Green leaf plates (20x20 studs)
    add_single_brick(-10, -10, 0, 20, 20, height_plates=6, mat_name="GREEN", studs=True, stud_step=2)
    add_single_brick(-5, -5, 6, 10, 10, height_plates=6, mat_name="LIME", studs=True, stud_step=2)

    # Bright Red 1x1 Round Stud Berries
    berry_coords = [
        (-6.0, -6.0, 6), (6.0, -6.0, 6), (-6.0, 6.0, 6), (6.0, 6.0, 6),
        (-2.5, 2.5, 12), (2.5, -2.5, 12), (0.0, 0.0, 12),
        (-5.0, 0.0, 6), (5.0, 0.0, 6), (0.0, -5.0, 6), (0.0, 5.0, 6)
    ]
    for bx, by, bz in berry_coords:
        add_cylinder_brick(bx, by, bz, radius_studs=1.0, height_plates=4, mat_name="RED", stud=True)

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
        print("Assembling 80% Finer LEGO Imperial Town Center...")
        build_lego_town_center(f"{models_dir}/pixel_town_center.glb")

    if target in ["all", "house"]:
        print("Assembling 80% Finer LEGO Pagoda House...")
        build_lego_house(f"{models_dir}/pixel_house.glb")

    if target in ["all", "barracks"]:
        print("Assembling 80% Finer LEGO Barracks...")
        build_lego_barracks(f"{models_dir}/pixel_barracks.glb")

    if target in ["all", "tower"]:
        print("Assembling 80% Finer LEGO Guard Watchtower...")
        build_lego_tower(f"{models_dir}/pixel_tower.glb")
        os.system(f"cp {models_dir}/pixel_tower.glb {models_dir}/pixel_guard_tower.glb")

    if target in ["all", "monolith"]:
        print("Assembling Scenic Ancient Monolith...")
        build_scenic_monolith(f"{models_dir}/scenic_monolith.glb")

    if target in ["all", "nature", "tree"]:
        print("Assembling 80% Finer LEGO Pine Tree...")
        build_lego_tree(f"{models_dir}/pixel_tree.glb")

    if target in ["all", "nature", "stone"]:
        print("Assembling 80% Finer LEGO Boulder...")
        build_lego_stone(f"{models_dir}/pixel_stone.glb")

    if target in ["all", "nature", "gold"]:
        print("Assembling 80% Finer LEGO Gold Vein...")
        build_lego_gold(f"{models_dir}/pixel_gold.glb")

    if target in ["all", "nature", "food"]:
        print("Assembling 80% Finer LEGO Berry Bush...")
        build_lego_berry_bush(f"{models_dir}/pixel_food.glb")

    print("\nAll 80% finer LEGO assemblies generated successfully!")
