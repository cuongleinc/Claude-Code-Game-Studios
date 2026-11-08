#!/usr/bin/env python3
"""
generate_pixel_asset_catalog.py
Generates at least 200 rich, stylized pixel art assets (32x32 and 48x48)
across Characters (128 frames), Nature & Trees (40 assets), and Mine Ores & Items (40 assets).
Uses pure Python standard library (zlib, struct) with zero external dependencies.
"""

import os
import zlib
import struct
import math

def save_png(filepath: str, width: int, height: int, rgba_bytes: bytearray):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    raw = bytearray()
    row_bytes = width * 4
    for y in range(height):
        raw.append(0) # Filter byte 0 (None)
        raw.extend(rgba_bytes[y * row_bytes : (y + 1) * row_bytes])

    compressed = zlib.compress(bytes(raw), 9)

    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xffffffff
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", compressed)
    png += chunk(b"IEND", b"")

    with open(filepath, "wb") as f:
        f.write(png)

class PixelCanvas:
    def __init__(self, width: int, height: int):
        self.w = width
        self.h = height
        self.buf = bytearray(width * height * 4)

    def set_pixel(self, x: int, y: int, r: int, g: int, b: int, a: int = 255):
        if 0 <= x < self.w and 0 <= y < self.h:
            idx = (y * self.w + x) * 4
            self.buf[idx] = r
            self.buf[idx + 1] = g
            self.buf[idx + 2] = b
            self.buf[idx + 3] = a

    def fill_rect(self, x0: int, y0: int, w: int, h: int, r: int, g: int, b: int, a: int = 255):
        for y in range(max(0, y0), min(self.h, y0 + h)):
            for x in range(max(0, x0), min(self.w, x0 + w)):
                self.set_pixel(x, y, r, g, b, a)

    def fill_circle(self, cx: int, cy: int, radius: int, r: int, g: int, b: int, a: int = 255):
        r_sq = radius * radius
        for y in range(max(0, cy - radius), min(self.h, cy + radius + 1)):
            for x in range(max(0, cx - radius), min(self.w, cx + radius + 1)):
                if (x - cx)**2 + (y - cy)**2 <= r_sq:
                    self.set_pixel(x, y, r, g, b, a)

    def draw_outline(self, outline_col=(20, 24, 30, 255)):
        # Add 1px dark border around non-transparent pixels
        border_pixels = []
        for y in range(self.h):
            for x in range(self.w):
                idx = (y * self.w + x) * 4
                if self.buf[idx + 3] == 0:
                    # Check neighbors
                    has_solid_neighbor = False
                    for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.w and 0 <= ny < self.h:
                            if self.buf[(ny * self.w + nx) * 4 + 3] > 0:
                                has_solid_neighbor = True
                                break
                    if has_solid_neighbor:
                        border_pixels.append((x, y))
        for bx, by in border_pixels:
            self.set_pixel(bx, by, *outline_col)

# ─────────────────────────────────────────────────────────────────────────────
# PALETTES
# ─────────────────────────────────────────────────────────────────────────────
PALETTE = {
    "SKIN_YELLOW": (255, 215, 0),
    "SKIN_SHADOW": (218, 165, 32),
    "ROYAL_BLUE": (28, 92, 196),
    "ROYAL_BLUE_DARK": (16, 54, 120),
    "RED_CORSAIR": (220, 38, 38),
    "RED_DARK": (153, 27, 27),
    "GOLD_SHINE": (250, 204, 21),
    "GOLD_MID": (234, 179, 8),
    "GOLD_DARK": (161, 98, 7),
    "STEEL_LIGHT": (226, 232, 240),
    "STEEL_MID": (148, 163, 184),
    "STEEL_DARK": (71, 85, 105),
    "PINE_DARK": (20, 83, 45),
    "PINE_LIGHT": (34, 197, 94),
    "OAK_GREEN": (22, 101, 52),
    "OAK_LIGHT": (74, 222, 128),
    "PALM_GREEN": (16, 185, 129),
    "BLOSSOM_PINK": (244, 114, 182),
    "BLOSSOM_LIGHT": (251, 207, 232),
    "AUTUMN_AMBER": (249, 115, 22),
    "TRUNK_BROWN": (120, 53, 15),
    "TRUNK_LIGHT": (180, 83, 9),
    "STONE_LIGHT": (203, 213, 225),
    "STONE_MID": (100, 116, 139),
    "STONE_DARK": (51, 65, 85),
    "RUBY_RED": (239, 68, 68),
    "SAPPHIRE_BLUE": (59, 130, 246),
    "EMERALD_GREEN": (16, 185, 129),
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. CHARACTER SPRITE GENERATOR (128 IMAGES)
# ─────────────────────────────────────────────────────────────────────────────
CHARACTERS = [
    ("villager", "Villager", (34, 197, 94), (180, 83, 9)),       # Green overalls, straw hat
    ("spearman", "Spearman", (28, 92, 196), (205, 127, 50)),     # Blue tunic, bronze helm
    ("archer", "Archer", (21, 128, 61), (120, 53, 15)),          # Forest green hood, leather
    ("royal_knight", "Royal Knight", (148, 163, 184), (234, 179, 8)), # Steel armor, gold plume
    ("island_lord", "Island Lord", (79, 70, 229), (250, 204, 21)),   # Royal purple, gold crown
    ("corsair_raider", "Corsair Raider", (220, 38, 38), (17, 24, 39)), # Red striped, black bandana
    ("clan_berserker", "Clan Berserker", (180, 83, 9), (239, 68, 68)), # Fur mantle, warpaint
    ("dread_captain", "Dread Captain", (30, 41, 59), (234, 179, 8)),   # Dark coat, captain hat
]

FRAMES = [
    ("idle_s", 0, 0, 0),
    ("idle_n", 0, 0, 1),
    ("idle_e", 0, 0, 2),
    ("idle_w", 0, 0, 3),
    ("walk_01", -2, 1, 0),
    ("walk_02", 0, 0, 0),
    ("walk_03", 2, -1, 0),
    ("walk_04", 0, 0, 0),
    ("attack_windup", 0, -2, 4),
    ("attack_strike", 3, 2, 5),
    ("attack_impact", 4, 1, 5),
    ("attack_recover", 1, 0, 0),
    ("hit_flinch", -2, 1, 6),
    ("die_fall", -3, 3, 7),
    ("die_ground", -4, 5, 8),
    ("portrait", 0, 0, 9)
]

def generate_character_frame(char_id: str, char_name: str, body_col: tuple, trim_col: tuple, frame_id: str, leg_off: int, arm_off: int, pose: int, out_path: str):
    c = PixelCanvas(32, 32)

    # Palette
    yellow = PALETTE["SKIN_YELLOW"]
    dark_yellow = PALETTE["SKIN_SHADOW"]

    if pose == 9: # Portrait Close-up
        # Head
        c.fill_circle(16, 16, 10, *yellow)
        # Eyes & Smile
        c.set_pixel(13, 15, 20, 20, 20)
        c.set_pixel(19, 15, 20, 20, 20)
        c.set_pixel(14, 20, 20, 20, 20)
        c.set_pixel(15, 21, 20, 20, 20)
        c.set_pixel(16, 21, 20, 20, 20)
        c.set_pixel(17, 21, 20, 20, 20)
        c.set_pixel(18, 20, 20, 20, 20)
        # Headgear
        c.fill_rect(8, 6, 16, 6, *trim_col)
        c.fill_rect(10, 3, 12, 3, *trim_col)
        c.draw_outline()
        save_png(out_path, 32, 32, c.buf)
        return

    if pose == 8: # Dead on Ground
        c.fill_rect(6, 24, 20, 6, *body_col)
        c.fill_rect(24, 23, 6, 6, *yellow)
        c.draw_outline()
        save_png(out_path, 32, 32, c.buf)
        return

    # 1. Legs (Micro-LEGO Block Legs)
    leg_y = 22
    c.fill_rect(11 + leg_off, leg_y, 4, 8, 30, 41, 59)
    c.fill_rect(17 - leg_off, leg_y, 4, 8, 30, 41, 59)
    # Shoes/Feet
    c.fill_rect(10 + leg_off, leg_y + 6, 5, 2, 15, 23, 42)
    c.fill_rect(17 - leg_off, leg_y + 6, 5, 2, 15, 23, 42)

    # 2. Torso (LEGO Trapezoidal Minifigure Torso)
    c.fill_rect(10, 13, 12, 9, *body_col)
    c.fill_rect(12, 14, 8, 7, *trim_col)

    # 3. Arms & C-Clamp Hands
    c.fill_rect(7, 14 + arm_off, 3, 7, *body_col)
    c.fill_rect(22, 14 - arm_off, 3, 7, *body_col)
    c.fill_rect(7, 21 + arm_off, 3, 2, *yellow)
    c.fill_rect(22, 21 - arm_off, 3, 2, *yellow)

    # 4. Cylindrical Minifigure Head & Top Stud
    c.fill_rect(12, 7, 8, 6, *yellow)
    c.fill_rect(14, 5, 4, 2, *yellow) # Top Stud

    # Eyes & Expression (Facing South/East/West)
    if pose != 1: # Not North
        c.set_pixel(14, 9, 20, 24, 30)
        c.set_pixel(17, 9, 20, 24, 30)
        c.set_pixel(15, 11, 20, 24, 30)
        c.set_pixel(16, 11, 20, 24, 30)

    # 5. Headgear
    c.fill_rect(10, 4, 12, 3, *trim_col)
    if char_id == "villager":
        # Broad straw hat brim
        c.fill_rect(8, 6, 16, 2, 217, 169, 78)
        c.fill_rect(11, 3, 10, 3, 217, 169, 78)
    elif char_id == "spearman":
        # Spartan crest
        c.fill_rect(15, 1, 2, 4, 28, 92, 196)
    elif char_id == "royal_knight":
        # Visor slit
        c.fill_rect(13, 9, 6, 2, 51, 65, 85)
    elif char_id == "island_lord":
        # Golden crown spikes
        c.set_pixel(11, 3, *PALETTE["GOLD_SHINE"])
        c.set_pixel(13, 2, *PALETTE["GOLD_SHINE"])
        c.set_pixel(15, 1, *PALETTE["GOLD_SHINE"])
        c.set_pixel(17, 2, *PALETTE["GOLD_SHINE"])
        c.set_pixel(19, 3, *PALETTE["GOLD_SHINE"])

    # 6. Weapon in Hand (Action Poses)
    if pose in [4, 5]: # Attack
        c.fill_rect(24, 10, 2, 14, *trim_col)
        c.fill_rect(23, 8, 4, 3, *PALETTE["STEEL_LIGHT"])

    c.draw_outline()
    save_png(out_path, 32, 32, c.buf)

# ─────────────────────────────────────────────────────────────────────────────
# 2. NATURE & TREES PIXEL ART (40 IMAGES)
# ─────────────────────────────────────────────────────────────────────────────
def generate_tree_sprite(tree_type: str, variant: int, out_path: str):
    c = PixelCanvas(48, 48)

    if tree_type == "pine":
        trunk_h = 10 + variant * 2
        c.fill_rect(22, 48 - trunk_h, 4, trunk_h, *PALETTE["TRUNK_BROWN"])
        # Stepped Pine Foliage
        col = PALETTE["PINE_DARK"] if variant % 2 == 0 else PALETTE["PINE_LIGHT"]
        layers = [
            (24, 48 - trunk_h - 2, 14),
            (24, 48 - trunk_h - 8, 11),
            (24, 48 - trunk_h - 14, 8),
            (24, 48 - trunk_h - 20, 5),
            (24, 48 - trunk_h - 25, 3),
        ]
        for cx, cy, r in layers:
            c.fill_circle(cx, cy, r, *col)
            c.set_pixel(cx - 2, cy - 2, *PALETTE["PINE_LIGHT"])

    elif tree_type == "oak":
        trunk_h = 12 + variant * 2
        c.fill_rect(21, 48 - trunk_h, 6, trunk_h, *PALETTE["TRUNK_BROWN"])
        # Big Rounded Canopy
        col = PALETTE["OAK_GREEN"] if variant < 4 else PALETTE["AUTUMN_AMBER"]
        c.fill_circle(24, 20, 14, *col)
        c.fill_circle(16, 22, 10, *col)
        c.fill_circle(32, 22, 10, *col)
        c.fill_circle(24, 14, 9, *PALETTE["OAK_LIGHT"] if variant < 4 else (255, 180, 50))

    elif tree_type == "palm":
        # Curved Trunk
        for i in range(18):
            tx = 24 - int(math.sin(i * 0.15) * 4)
            ty = 48 - i
            c.fill_rect(tx, ty, 3, 2, *PALETTE["TRUNK_LIGHT"])
        # Palm Fronds
        for angle in [0, 45, 90, 135, 180, 225, 270, 315]:
            rad = math.radians(angle)
            for d in range(4, 15):
                fx = int(24 + math.cos(rad) * d)
                fy = int(30 + math.sin(rad) * d * 0.6)
                c.set_pixel(fx, fy, *PALETTE["PALM_GREEN"])
        # Coconuts
        c.fill_circle(23, 31, 2, *PALETTE["TRUNK_BROWN"])
        c.fill_circle(25, 32, 2, *PALETTE["TRUNK_BROWN"])

    elif tree_type == "blossom":
        c.fill_rect(22, 34, 4, 14, *PALETTE["TRUNK_BROWN"])
        col_main = PALETTE["BLOSSOM_PINK"]
        col_light = PALETTE["BLOSSOM_LIGHT"]
        c.fill_circle(24, 20, 13, *col_main)
        c.fill_circle(17, 22, 9, *col_main)
        c.fill_circle(31, 21, 9, *col_main)
        c.fill_circle(24, 15, 7, *col_light)
        # Petals falling
        c.set_pixel(15, 36, *col_light)
        c.set_pixel(33, 38, *col_light)

    elif tree_type == "autumn":
        c.fill_rect(22, 34, 4, 14, *PALETTE["TRUNK_BROWN"])
        c.fill_circle(24, 20, 13, 234, 88, 12)
        c.fill_circle(16, 22, 9, 249, 115, 22)
        c.fill_circle(32, 22, 9, 234, 179, 8)

    c.draw_outline()
    save_png(out_path, 48, 48, c.buf)

def generate_shrub_flora(name: str, out_path: str):
    c = PixelCanvas(32, 32)
    if "berries" in name:
        c.fill_circle(16, 18, 9, *PALETTE["OAK_GREEN"])
        c.fill_circle(12, 19, 6, *PALETTE["OAK_GREEN"])
        c.fill_circle(20, 19, 6, *PALETTE["OAK_GREEN"])
        # Berries
        for bx, by in [(14, 15), (18, 16), (12, 20), (16, 21), (20, 20)]:
            c.fill_circle(bx, by, 2, *PALETTE["RUBY_RED"])
    elif "wheat" in name:
        for i in range(4):
            wx = 10 + i * 4
            c.fill_rect(wx, 12, 2, 16, 234, 179, 8)
            c.fill_circle(wx + 1, 10, 3, 250, 204, 21)
    elif "fern" in name or "flower" in name or "mushroom" in name:
        c.fill_circle(16, 20, 7, *PALETTE["OAK_LIGHT"])
        c.fill_circle(16, 14, 4, *PALETTE["GOLD_SHINE"])
    elif "coral" in name:
        c.fill_rect(12, 14, 3, 14, *PALETTE["RUBY_RED"])
        c.fill_rect(17, 10, 3, 18, *PALETTE["RUBY_RED"])
        c.fill_rect(22, 16, 3, 12, *PALETTE["RUBY_RED"])

    c.draw_outline()
    save_png(out_path, 32, 32, c.buf)

# ─────────────────────────────────────────────────────────────────────────────
# 3. MINE ORES & CRAFTED ITEMS (40 IMAGES)
# ─────────────────────────────────────────────────────────────────────────────
def generate_ore_item_sprite(item_key: str, out_path: str):
    c = PixelCanvas(32, 32)

    if "gold" in item_key:
        if "ore" in item_key:
            c.fill_rect(8, 10, 16, 16, *PALETTE["STONE_DARK"])
            c.fill_circle(16, 16, 7, *PALETTE["GOLD_SHINE"])
            c.fill_rect(12, 14, 4, 4, *PALETTE["GOLD_MID"])
        elif "ingot" in item_key:
            c.fill_rect(8, 14, 16, 8, *PALETTE["GOLD_MID"])
            c.fill_rect(10, 12, 12, 2, *PALETTE["GOLD_SHINE"])
        else: # Coins
            c.fill_circle(14, 16, 6, *PALETTE["GOLD_SHINE"])
            c.fill_circle(18, 14, 6, *PALETTE["GOLD_MID"])

    elif "stone" in item_key or "granite" in item_key or "slate" in item_key or "runestone" in item_key:
        c.fill_rect(8, 10, 16, 16, *PALETTE["STONE_MID"])
        c.fill_rect(10, 12, 12, 12, *PALETTE["STONE_LIGHT"])
        if "runestone" in item_key:
            # Blue runic spiral
            c.fill_rect(14, 14, 4, 2, *PALETTE["SAPPHIRE_BLUE"])
            c.fill_rect(16, 16, 2, 4, *PALETTE["SAPPHIRE_BLUE"])

    elif "iron" in item_key:
        c.fill_rect(9, 12, 14, 12, *PALETTE["STEEL_MID"])
        c.fill_rect(11, 14, 10, 8, *PALETTE["STEEL_LIGHT"])

    elif "copper" in item_key:
        c.fill_rect(9, 12, 14, 12, 180, 83, 9)
        c.fill_rect(11, 14, 10, 8, 217, 119, 6)

    elif "gem" in item_key or "ruby" in item_key or "sapphire" in item_key or "emerald" in item_key:
        col = PALETTE["RUBY_RED"] if "ruby" in item_key else (PALETTE["SAPPHIRE_BLUE"] if "sapphire" in item_key else PALETTE["EMERALD_GREEN"])
        c.fill_circle(16, 16, 7, *col)
        c.set_pixel(14, 14, 255, 255, 255)

    elif "tool" in item_key:
        c.fill_rect(14, 10, 4, 16, *PALETTE["TRUNK_BROWN"])
        c.fill_rect(10, 8, 12, 5, *PALETTE["STEEL_LIGHT"])

    elif "weapon" in item_key:
        if "sword" in item_key or "cutlass" in item_key:
            c.fill_rect(15, 6, 2, 18, *PALETTE["STEEL_LIGHT"])
            c.fill_rect(12, 22, 8, 2, *PALETTE["GOLD_SHINE"])
            c.fill_rect(15, 24, 2, 4, *PALETTE["TRUNK_BROWN"])
        elif "bow" in item_key:
            for i in range(16):
                bx = 12 + int(math.sin(i * 0.2) * 5)
                c.set_pixel(bx, 8 + i, *PALETTE["TRUNK_BROWN"])
                c.set_pixel(12, 8 + i, 220, 220, 220) # String
        elif "spear" in item_key:
            c.fill_rect(15, 4, 2, 24, *PALETTE["TRUNK_BROWN"])
            c.fill_rect(14, 3, 4, 5, *PALETTE["STEEL_LIGHT"])
        else: # Axe
            c.fill_rect(15, 8, 2, 20, *PALETTE["TRUNK_BROWN"])
            c.fill_rect(9, 8, 6, 8, *PALETTE["STEEL_LIGHT"])

    elif "shield" in item_key:
        c.fill_circle(16, 16, 9, *PALETTE["ROYAL_BLUE"])
        c.fill_circle(16, 16, 4, *PALETTE["GOLD_SHINE"])

    elif "armor" in item_key:
        c.fill_rect(10, 10, 12, 10, *PALETTE["STEEL_LIGHT"])
        c.fill_rect(12, 14, 8, 2, *PALETTE["STONE_DARK"]) # Visor

    elif "food" in item_key:
        c.fill_circle(16, 16, 8, 217, 119, 6) # Bread loaf / Roast meat
        c.fill_circle(14, 14, 3, 250, 204, 21)

    c.draw_outline()
    save_png(out_path, 32, 32, c.buf)

# ─────────────────────────────────────────────────────────────────────────────
# MAIN DISPATCHER
# ─────────────────────────────────────────────────────────────────────────────
def main():
    root = "/Users/cuong.le/Document/build-the-game"
    count = 0

    print("Generating Character Animation & Directional Sprites (128)...")
    char_dir = os.path.join(root, "assets", "pixel_art", "characters")
    for cid, cname, bcol, tcol in CHARACTERS:
        for fid, loff, aoff, pose in FRAMES:
            path = os.path.join(char_dir, f"{cid}_{fid}.png")
            generate_character_frame(cid, cname, bcol, tcol, fid, loff, aoff, pose, path)
            count += 1

    print("Generating Trees & Flora Sprites (40)...")
    env_dir = os.path.join(root, "assets", "pixel_art", "environment")
    tree_types = ["pine", "oak", "palm", "blossom", "autumn"]
    for tt in tree_types:
        for v in range(1, 6):
            path = os.path.join(env_dir, f"tree_{tt}_{v:02d}.png")
            generate_tree_sprite(tt, v, path)
            count += 1

    shrubs = [
        "bush_berries_01", "bush_berries_02", "bush_berries_03",
        "plant_ferns_01", "plant_mushrooms_01", "flower_dandelion_01", "flower_clover_01",
        "crop_wheat_01", "crop_wheat_02", "crop_wheat_03", "crop_wheat_04",
        "reef_coral_01", "reef_coral_02", "reef_coral_03", "reef_coral_04"
    ]
    for s in shrubs:
        path = os.path.join(env_dir, f"{s}.png")
        generate_shrub_flora(s, path)
        count += 1

    print("Generating Mine Ores & Crafting Items (40)...")
    item_dir = os.path.join(root, "assets", "pixel_art", "items")
    items = [
        "ore_gold_rock", "ore_gold_crystals", "ore_gold_nugget", "item_gold_ingot", "item_gold_coins",
        "ore_stone_crag", "ore_granite_block", "ore_slate_slab", "item_carved_runestone",
        "ore_iron_rock", "ore_iron_ingot", "ore_copper_rock", "ore_copper_ingot",
        "gem_ruby_rough", "gem_ruby_cut", "gem_sapphire_cut", "gem_emerald_cut",
        "tool_wood_axe", "tool_pickaxe", "tool_farmer_rake", "tool_builder_hammer",
        "weapon_bronze_spear", "weapon_iron_spear", "weapon_recurve_bow", "weapon_crossbow",
        "weapon_iron_sword", "weapon_royal_broadsword", "weapon_pirate_cutlass", "weapon_battleaxe",
        "shield_wooden_buckler", "shield_royal_knight", "shield_pirate_skull", "shield_totem_crest",
        "armor_peasant_straw_hat", "armor_hoplite_helm", "armor_knight_visor", "armor_imperial_crown",
        "food_berries_basket", "food_bread_loaf", "food_roasted_meat"
    ]
    for it in items:
        path = os.path.join(item_dir, f"{it}.png")
        generate_ore_item_sprite(it, path)
        count += 1

    print(f"SUCCESS: Generated {count} total pixel art images in {root}/assets/pixel_art/!")

if __name__ == "__main__":
    main()
