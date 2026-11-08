#!/usr/bin/env python3
"""
Free 3D Model Importer & Converter for Island Empire
Converts any downloaded free 3D model (OBJ, FBX, BLEND, GLTF, DAE, ZIP) into game-ready .GLB
using Blender 5.2 LTS, scaling and centering it for Godot 4.7.
"""

import sys
import os
import shutil
import zipfile
import subprocess
import argparse

BLENDER_BIN = "/opt/homebrew/bin/blender"
OUTPUT_DIR = "/Users/cuong.le/Document/build-the-game/assets/models"

CONVERT_SCRIPT_TEMPLATE = """
import bpy
import os
import sys

input_file = "{input_file}"
output_glb = "{output_glb}"
target_size = {target_size}

bpy.ops.wm.read_factory_settings(use_empty=True)

ext = os.path.splitext(input_file)[1].lower()
print(f"Importing {{input_file}} (ext: {{ext}})...")

if ext in ['.gltf', '.glb']:
    bpy.ops.import_scene.gltf(filepath=input_file)
elif ext == '.obj':
    try:
        bpy.ops.wm.obj_import(filepath=input_file)
    except:
        bpy.ops.import_scene.obj(filepath=input_file)
elif ext == '.fbx':
    bpy.ops.import_scene.fbx(filepath=input_file)
elif ext == '.blend':
    bpy.ops.wm.open_mainfile(filepath=input_file)
elif ext == '.dae':
    bpy.ops.wm.collada_import(filepath=input_file)
else:
    print(f"Unsupported format: {{ext}}")
    sys.exit(1)

# Calculate bounding box & normalize scale
bpy.ops.object.select_all(action='SELECT')
selected = bpy.context.selected_objects
if not selected:
    print("No objects imported!")
    sys.exit(1)

# Compute total dimensions
min_x = min(o.location.x - o.dimensions.x/2 for o in selected)
max_x = max(o.location.x + o.dimensions.x/2 for o in selected)
min_y = min(o.location.y - o.dimensions.y/2 for o in selected)
max_y = max(o.location.y + o.dimensions.y/2 for o in selected)
min_z = min(o.location.z for o in selected)
max_z = max(o.location.z + o.dimensions.z for o in selected)

cur_max_dim = max(max_x - min_x, max_y - min_y, max_z - min_z)
scale_factor = 1.0
if cur_max_dim > 0.001 and target_size > 0:
    scale_factor = target_size / cur_max_dim
    print(f"Scaling model from {{cur_max_dim:.2f}} to {{target_size:.2f}} (factor: {{scale_factor:.4f}})")
    for o in selected:
        o.scale *= scale_factor

bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

# Export clean GLB
print(f"Exporting to {{output_glb}}...")
bpy.ops.export_scene.gltf(
    filepath=output_glb,
    export_format='GLB',
    use_selection=True,
    export_apply=True
)
print("GLB export complete!")
"""

def process_file(source_path: str, target_name: str, target_size: float = 2.8):
    source_path = os.path.abspath(os.path.expanduser(source_path))
    if not os.path.exists(source_path):
        print(f"❌ File not found: {source_path}")
        return False

    temp_dir = "/tmp/model_import"
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir, exist_ok=True)

    input_model_file = source_path
    if source_path.lower().endswith(".zip"):
        print(f"📦 Extracting zip: {source_path}...")
        with zipfile.ZipFile(source_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
        
        # Search for 3D model files inside
        found = []
        for root, _, files in os.walk(temp_dir):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in [".obj", ".fbx", ".gltf", ".glb", ".blend", ".dae"]:
                    found.append(os.path.join(root, f))
        if not found:
            print("❌ No 3D model file found inside zip!")
            return False
        # Prefer gltf/glb, then blend, then fbx, then obj
        found.sort(key=lambda x: [".gltf", ".glb", ".blend", ".fbx", ".obj", ".dae"].index(os.path.splitext(x)[1].lower()) if os.path.splitext(x)[1].lower() in [".gltf", ".glb", ".blend", ".fbx", ".obj", ".dae"] else 99)
        input_model_file = found[0]
        print(f"Found model: {input_model_file}")

    output_glb = os.path.join(OUTPUT_DIR, f"{target_name}.glb")
    script_path = os.path.join(temp_dir, "convert.py")
    script_content = CONVERT_SCRIPT_TEMPLATE.format(
        input_file=input_model_file,
        output_glb=output_glb,
        target_size=target_size
    )
    with open(script_path, "w") as f:
        f.write(script_content)

    print(f"🔄 Converting via Blender: {input_model_file} -> {output_glb}...")
    cmd = [BLENDER_BIN, "--background", "--python", script_path]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        print(f"❌ Blender conversion error:\n{res.stderr}\n{res.stdout}")
        return False

    print(f"✅ Successfully created {output_glb}!")
    
    # Trigger Godot reimport
    print("🔄 Re-indexing in Godot Engine...")
    subprocess.run(["godot", "--headless", "--editor", "--quit"], cwd="/Users/cuong.le/Document/build-the-game")
    print(f"✨ Ready! Model is active at res://assets/models/{target_name}.glb")
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Import Free 3D Model into Island Empire")
    parser.add_argument("input", help="Path to downloaded 3D model (zip, obj, fbx, blend, gltf)")
    parser.add_argument("--name", default="house", help="Target name in assets/models/<name>.glb (default: house)")
    parser.add_argument("--size", type=float, default=2.8, help="Target bounding box dimension (default: 2.8)")
    args = parser.parse_args()

    success = process_file(args.input, args.name, args.size)
    sys.exit(0 if success else 1)
