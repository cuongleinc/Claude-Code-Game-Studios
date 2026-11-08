#!/usr/bin/env python3
"""
pixel_to_voxel.py
Converts a 2D pixel art PNG into a real 3D Voxel Model (.glb) with full 3D depth,
watertight exterior-only geometry, vertex colors, and proper game engine orientation.
"""

import sys
import math
import bpy

def convert_pixel_to_voxel(input_png: str, output_glb: str, target_height: float = 3.6):
    # Clear existing scene
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
        print("Error: No solid pixels found in image!")
        sys.exit(1)

    tree_pixel_height = max_y - min_y + 1
    voxel_scale = target_height / float(tree_pixel_height)
    print(f"Tree pixel height: {tree_pixel_height}, voxel size: {voxel_scale:.4f}m")

    # Global horizontal center of the tree
    all_xs = [x for x, y in grid_2d.keys()]
    global_xc = (min(all_xs) + max(all_xs)) / 2.0

    # Build 3D Voxel Volume: (vx, vz, vy) -> (r, g, b)
    # vx: X (horizontal right)
    # vz: Y in Blender (depth forward/back)
    # vy: Z in Blender (height up/down)
    voxels = {}
    for (x, y), (r, g, b) in grid_2d.items():
        min_x, max_x = row_bounds[y]
        xc = (min_x + max_x) / 2.0
        R = max(1.0, (max_x - min_x) / 2.0)
        d = abs(x - xc)
        ratio = min(1.0, d / (R + 0.3))
        # Rounded radial depth
        z_max = int(round(R * math.sqrt(max(0.0, 1.0 - ratio * ratio)) * 0.72))
        z_max = max(1, min(z_max, 10))

        for z in range(-z_max, z_max + 1):
            depth_shade = 1.0 - (abs(z) / float(z_max + 1)) * 0.12
            voxels[(x, z, y)] = (r * depth_shade, g * depth_shade, b * depth_shade)

    print(f"Total 3D Voxels: {len(voxels)}")

    # Cube corner offsets in Blender coords: (X, Y, Z)
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

    # (dx, dy, dz) in Blender coords (X=Right, Y=Depth, Z=Up)
    face_definitions = [
        (( 1,  0,  0), (1, 2, 6, 5), 0.95),  # +X (Right)
        ((-1,  0,  0), (0, 4, 7, 3), 0.90),  # -X (Left)
        (( 0,  1,  0), (2, 3, 7, 6), 1.00),  # +Y (Front depth)
        (( 0, -1,  0), (0, 1, 5, 4), 0.85),  # -Y (Back depth)
        (( 0,  0,  1), (4, 5, 6, 7), 1.06),  # +Z (Top - Upward lit)
        (( 0,  0, -1), (1, 0, 3, 2), 0.76),  # -Z (Bottom - Downward shaded)
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

    for (vx, vz, vy), (r, g, b) in voxels.items():
        # Center tree at base ground: X=centered, Y(depth)=centered, Z(height)=0 at base
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

    print(f"Generated Mesh: {len(mesh_vertices)} vertices, {len(mesh_faces)} quads")

    # Create Blender mesh & object
    mesh = bpy.data.meshes.new("PixelTree_Mesh")
    obj = bpy.data.objects.new("PixelTree", mesh)
    bpy.context.collection.objects.link(obj)

    mesh.from_pydata(mesh_vertices, [], mesh_faces)
    mesh.update()

    # Assign Vertex Colors
    col_attr = mesh.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
    for poly_idx, poly in enumerate(mesh.polygons):
        col = face_colors[poly_idx]
        for loop_idx in poly.loop_indices:
            col_attr.data[loop_idx].color = col

    # Create Material using vertex color
    mat = bpy.data.materials.new("PixelArt_Mat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Roughness"].default_value = 0.8
        vcol_node = mat.node_tree.nodes.new("ShaderNodeAttribute")
        vcol_node.attribute_name = "Color"
        mat.node_tree.links.new(vcol_node.outputs["Color"], bsdf.inputs["Base Color"])
    obj.data.materials.append(mat)

    # Export to GLB
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
    print(f"Successfully exported 3D Voxel Model to: {output_glb}")

if __name__ == "__main__":
    argv = sys.argv
    if "--" in argv:
        args = argv[argv.index("--") + 1:]
    else:
        args = argv[1:]

    in_path = args[0] if len(args) > 0 else "assets/environment/pixel_tree.png"
    out_path = args[1] if len(args) > 1 else "assets/models/pixel_tree.glb"
    h = float(args[2]) if len(args) > 2 else 3.6

    convert_pixel_to_voxel(in_path, out_path, h)
