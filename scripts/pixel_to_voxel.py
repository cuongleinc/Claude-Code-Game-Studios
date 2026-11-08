#!/usr/bin/env python3
"""
pixel_to_voxel.py
Converts 2D pixel art PNGs into real 3D Voxel Models (.glb) with:
- Full blocky 3D depth and thickness (no thin wafers or cards)
- Watertight exterior-only geometry with zero internal faces
- Baked directional voxel lighting and vertex colors
- Scaled and centered at ground base for Godot 4.x
"""

import sys
import math
import bpy

def convert_pixel_to_voxel(input_png: str, output_glb: str, target_height: float = 3.6, shape_mode: str = "auto", depth_ratio: float = 0.65):
    # Reset factory settings to ensure a clean empty scene
    bpy.ops.wm.read_factory_settings(use_empty=True)

    img = bpy.data.images.load(input_png)
    w, h = img.size[0], img.size[1]
    pix = list(img.pixels) # RGBA floats

    # Find solid pixels and horizontal bounds per row
    grid_2d = {}
    row_bounds = {}
    min_y, max_y = h, 0

    for y in range(h):
        xs = []
        for x in range(w):
            idx = (y * w + x) * 4
            r, g, b, a = pix[idx], pix[idx+1], pix[idx+2], pix[idx+3]
            if a > 0.15:
                grid_2d[(x, y)] = (r, g, b)
                xs.append(x)
        if xs:
            row_bounds[y] = (min(xs), max(xs))
            min_y = min(min_y, y)
            max_y = max(max_y, y)

    if not grid_2d:
        print(f"Error: No solid pixels found in {input_png}!")
        sys.exit(1)

    pixel_height = max_y - min_y + 1
    voxel_scale = target_height / float(pixel_height)
    all_xs = [x for x, y in grid_2d.keys()]
    global_xc = (min(all_xs) + max(all_xs)) / 2.0

    if shape_mode == "auto":
        lower_path = input_png.lower()
        if any(k in lower_path for k in ["house", "town", "barrack", "tower", "castle", "building"]):
            shape_mode = "box"
        else:
            shape_mode = "round"

    print(f"Converting: {input_png}")
    print(f"  Height: {pixel_height}px | Scale: {voxel_scale:.4f}m | Mode: {shape_mode} | Depth Ratio: {depth_ratio}")

    voxels = {}

    for (x, y), (r, g, b) in grid_2d.items():
        min_x, max_x = row_bounds[y]
        xc = (min_x + max_x) / 2.0
        R = max(1.0, (max_x - min_x) / 2.0)
        d = abs(x - xc)
        u = min(1.0, d / (R + 0.1))

        if shape_mode in ["box", "building"]:
            # Squircle / Chamfered Block profile: flat face across 80% of width, chunky corners
            # Never tapers to a razor edge: outer edges retain at least 38% thickness
            profile = math.pow(max(0.0, 1.0 - math.pow(u, 4)), 0.25) * 0.62 + 0.38
            z_max = max(2, int(round(R * depth_ratio * profile)))
        else:
            # Round / Spherical profile for trees, boulders, gold veins, berry bushes
            profile = math.sqrt(max(0.0, 1.0 - u * u)) * 0.88 + 0.12
            z_max = max(1, int(round(R * depth_ratio * profile)))

        # Fill solid depth from -z_max to +z_max
        for z in range(-z_max, z_max + 1):
            if z >= 0:
                # Front hemisphere: clean pixel art color with subtle edge lighting
                front_shade = 1.0 - (1.0 - (z / float(z_max + 1))) * 0.05
                voxels[(x, z, y)] = (r * front_shade, g * front_shade, b * front_shade)
            else:
                # Rear hemisphere: natural ambient occlusion shading
                back_shade = 0.80 + (0.18 * (1.0 + z / float(z_max + 1)))
                voxels[(x, z, y)] = (r * back_shade, g * back_shade, b * back_shade)

    print(f"  Total Solid 3D Voxels: {len(voxels):,}")

    # Cube corner offsets in Blender coordinates: (X=Right, Y=Depth, Z=Height)
    cube_verts = [
        (-0.5, -0.5, -0.5), # 0
        ( 0.5, -0.5, -0.5), # 1
        ( 0.5,  0.5, -0.5), # 2
        (-0.5,  0.5, -0.5), # 3
        (-0.5, -0.5,  0.5), # 4
        ( 0.5, -0.5,  0.5), # 5
        ( 0.5,  0.5,  0.5), # 6
        (-0.5,  0.5,  0.5), # 7
    ]

    # Face definitions with crisp voxel directional shading
    face_definitions = [
        (( 1,  0,  0), (1, 2, 6, 5), 0.94),  # +X (Right side)
        ((-1,  0,  0), (0, 4, 7, 3), 0.88),  # -X (Left side)
        (( 0,  1,  0), (2, 3, 7, 6), 1.02),  # +Y (Front depth face)
        (( 0, -1,  0), (0, 1, 5, 4), 0.82),  # -Y (Back depth face)
        (( 0,  0,  1), (4, 5, 6, 7), 1.08),  # +Z (Top face - skylight)
        (( 0,  0, -1), (1, 0, 3, 2), 0.72),  # -Z (Bottom face - ground shade)
    ]

    mesh_vertices = []
    mesh_faces = []
    face_colors = []
    vert_map = {}

    def get_vert_index(gx, gy, gz):
        key = (round(gx, 5), round(gy, 5), round(gz, 5))
        if key not in vert_map:
            vert_map[key] = len(mesh_vertices)
            mesh_vertices.append((gx, gy, gz))
        return vert_map[key]

    # Generate watertight boundary faces only
    for (vx, vz, vy), (r, g, b) in voxels.items():
        world_x = (vx - global_xc) * voxel_scale
        world_y = vz * voxel_scale
        world_z = (vy - min_y) * voxel_scale

        for (dx, dy, dz), face_indices, shade_mult in face_definitions:
            neighbor = (vx + dx, vz + dy, vy + dz)
            if neighbor not in voxels:
                # Exposed boundary face
                face_quad = []
                for vi in face_indices:
                    cx, cy, cz = cube_verts[vi]
                    gx = world_x + cx * voxel_scale
                    gy = world_y + cy * voxel_scale
                    gz = world_z + cz * voxel_scale
                    face_quad.append(get_vert_index(gx, gy, gz))

                mesh_faces.append(face_quad)
                fr = min(1.0, max(0.0, r * shade_mult))
                fg = min(1.0, max(0.0, g * shade_mult))
                fb = min(1.0, max(0.0, b * shade_mult))
                face_colors.append((fr, fg, fb, 1.0))

    print(f"  Boundary Mesh: {len(mesh_vertices):,} vertices, {len(mesh_faces):,} quads")

    # Create Blender Mesh and Object
    mesh = bpy.data.meshes.new("Voxel_Mesh")
    obj = bpy.data.objects.new("VoxelObject", mesh)
    bpy.context.collection.objects.link(obj)

    mesh.from_pydata(mesh_vertices, [], mesh_faces)
    mesh.update()

    # Assign Vertex Colors
    col_attr = mesh.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
    for poly_idx, poly in enumerate(mesh.polygons):
        col = face_colors[poly_idx]
        for loop_idx in poly.loop_indices:
            col_attr.data[loop_idx].color = col

    # Material with Vertex Color binding
    mat = bpy.data.materials.new("Voxel_Mat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Roughness"].default_value = 0.85
        vcol_node = mat.node_tree.nodes.new("ShaderNodeAttribute")
        vcol_node.attribute_name = "Color"
        mat.node_tree.links.new(vcol_node.outputs["Color"], bsdf.inputs["Base Color"])
    obj.data.materials.append(mat)

    # Export clean GLB
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    bpy.ops.export_scene.gltf(
        filepath=output_glb,
        use_selection=True,
        export_format="GLB",
        export_attributes=True,
        export_materials="EXPORT",
        export_apply=True
    )
    print(f"  Exported -> {output_glb}\n")

if __name__ == "__main__":
    argv = sys.argv
    if "--" in argv:
        args = argv[argv.index("--") + 1:]
    else:
        args = argv[1:]

    in_path = args[0] if len(args) > 0 else "assets/environment/pixel_tree.png"
    out_path = args[1] if len(args) > 1 else "assets/models/pixel_tree.glb"
    h = float(args[2]) if len(args) > 2 else 3.6
    mode = args[3] if len(args) > 3 else "auto"
    ratio = float(args[4]) if len(args) > 4 else (0.65 if mode in ["box", "building"] else 0.90)

    convert_pixel_to_voxel(in_path, out_path, h, mode, ratio)
