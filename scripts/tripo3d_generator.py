#!/usr/bin/env python3
"""
Tripo3D Automated 3D Model Generator for Island Empire
Integrates with Tripo3D API V3 (https://developers.tripo3d.ai/en/docs/quick-start)

Capabilities:
1. Account balance & quota verification (/v3/account/balance)
2. Text-to-3D model generation with custom tailored prompts (/v3/generation/text-to-model)
3. Image-to-3D model generation with automatic file upload (/v3/files and /v3/generation/image-to-model)
4. Real-time task polling and progress tracking
5. Automated .glb download and direct Godot pipeline integration
"""

import sys
import os
import json
import time
import argparse
import urllib.request
import urllib.error

DEFAULT_API_KEY = "tsk_0FncaQCbHQ3WXa1KM-IS3B6oahHlxhBThg_ol-JaWL1"
BASE_URL = "https://openapi.tripo3d.ai/v3"
DEFAULT_OUTPUT_DIR = "/Users/cuong.le/Document/build-the-game/assets/models"

DEFAULT_HOUSE_PROMPT = (
    "A stylized East-Asian fantasy pagoda cottage diorama, traditional Chinese Japanese architecture. "
    "Two-story timber-framed pavilion with warm ivory plaster walls, curved flared hip-and-gable pagoda roofs "
    "with glazed dark blue-grey slate tiles and terracotta cinnabar ridge crests. A second-floor open wooden "
    "balcony with carved railings and a circular wooden moon window. Left side features a tall stone brick chimney "
    "extending past the roof. Front entrance features stone steps, double wooden doors with red couplet banners, "
    "lion knocker rings, and hanging red paper lanterns. Beside the entrance is a small bonsai cloud pine tree on "
    "mossy stone base. Isometric game asset, clean manifold geometry, PBR textures, high quality."
)

DEFAULT_NEGATIVE_PROMPT = (
    "blurry, floating disconnected parts, deformed, low resolution, broken topology, holes in mesh"
)

def get_headers(api_key: str, content_type: str = "application/json") -> dict:
    headers = {
        "Authorization": f"Bearer {api_key}"
    }
    if content_type:
        headers["Content-Type"] = content_type
    return headers

def check_balance(api_key: str) -> dict:
    url = f"{BASE_URL}/account/balance"
    req = urllib.request.Request(url, headers=get_headers(api_key))
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("data", {})
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        print(f"❌ Failed to fetch balance: HTTP {e.code} - {err_msg}")
        return {}

def upload_file(api_key: str, filepath: str) -> str:
    """Uploads an image file using multipart/form-data and returns a file_token."""
    url = f"{BASE_URL}/files"
    filename = os.path.basename(filepath)
    with open(filepath, "rb") as f:
        file_bytes = f.read()

    boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    body = bytearray()
    body.extend(f"--{boundary}\r\n".encode("utf-8"))
    body.extend(f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'.encode("utf-8"))
    body.extend(b"Content-Type: image/jpeg\r\n\r\n")
    body.extend(file_bytes)
    body.extend(f"\r\n--{boundary}--\r\n".encode("utf-8"))

    req = urllib.request.Request(
        url,
        data=bytes(body),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": f"multipart/form-data; boundary={boundary}"
        }
    )

    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        if res.get("code") == 0:
            token = res["data"]["file_token"]
            print(f"✅ Image uploaded successfully. File token: {token}")
            return token
        else:
            raise RuntimeError(f"Upload failed: {res}")

def create_text_to_model_task(api_key: str, prompt: str, model: str = "v3.1-20260211") -> str:
    url = f"{BASE_URL}/generation/text-to-model"
    payload = {
        "prompt": prompt,
        "negative_prompt": DEFAULT_NEGATIVE_PROMPT,
        "model": model,
        "texture": True,
        "pbr": True
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers=get_headers(api_key)
    )
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        if res.get("code") == 0:
            return res["data"]["task_id"]
        else:
            raise RuntimeError(f"Task creation failed: {res}")

def create_image_to_model_task(api_key: str, file_token: str, model: str = "v3.1-20260211") -> str:
    url = f"{BASE_URL}/generation/image-to-model"
    payload = {
        "input": file_token,
        "model": model,
        "texture": True,
        "pbr": True
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers=get_headers(api_key)
    )
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        if res.get("code") == 0:
            return res["data"]["task_id"]
        else:
            raise RuntimeError(f"Task creation failed: {res}")

def poll_task(api_key: str, task_id: str, max_retries: int = 300, interval: float = 2.0) -> dict:
    url = f"{BASE_URL}/tasks/{task_id}"
    req = urllib.request.Request(url, headers=get_headers(api_key))
    print(f"⏳ Polling Tripo3D task {task_id}...")

    for i in range(max_retries):
        try:
            with urllib.request.urlopen(req) as resp:
                res = json.loads(resp.read().decode("utf-8"))
                data = res.get("data", {})
                status = data.get("status", "unknown")
                progress = data.get("progress", 0)

                sys.stdout.write(f"\rStatus: {status.upper()} | Progress: {progress}% (Attempt {i+1}/{max_retries})")
                sys.stdout.flush()

                if status == "success":
                    print("\n🎉 Model generation succeeded!")
                    return data
                elif status in ("failed", "cancelled", "banned", "expired"):
                    print(f"\n❌ Task ended with status: {status}")
                    raise RuntimeError(f"Task {task_id} failed with status: {status}")
        except urllib.error.HTTPError as e:
            print(f"\nHTTP error while polling: {e}")

        time.sleep(interval)

    raise TimeoutError(f"Task {task_id} polling timed out after {max_retries * interval}s")

def download_file(url: str, dest_path: str):
    print(f"📥 Downloading 3D GLB from: {url}")
    print(f"💾 Saving to: {dest_path}")
    urllib.request.urlretrieve(url, dest_path)
    file_size_kb = os.path.getsize(dest_path) / 1024.0
    print(f"✅ Successfully downloaded {dest_path} ({file_size_kb:.1f} KB)")

def main():
    parser = argparse.ArgumentParser(description="Tripo3D Model Generator for Island Empire")
    parser.add_argument("--api-key", default=os.environ.get("TRIPO_API_KEY", DEFAULT_API_KEY), help="Tripo3D API Key")
    parser.add_argument("--mode", choices=["text", "image"], default="text", help="Generation mode")
    parser.add_argument("--prompt", default=DEFAULT_HOUSE_PROMPT, help="Text prompt")
    parser.add_argument("--image", default="", help="Path to image for image-to-model mode")
    parser.add_argument("--model", default="v3.1-20260211", help="Tripo AI model version")
    parser.add_argument("--output", default=os.path.join(DEFAULT_OUTPUT_DIR, "house.glb"), help="Output GLB path")
    parser.add_argument("--check-only", action="store_true", help="Only check balance and connectivity")
    args = parser.parse_args()

    print("========================================")
    print("      TRIPO3D ASSET GENERATOR V3        ")
    print("========================================")
    
    # 1. Balance verification
    print("Checking Tripo3D account status...")
    bal = check_balance(args.api_key)
    balance_val = bal.get("balance", 0.0)
    frozen_val = bal.get("frozen", 0.0)
    print(f"💳 Available Balance: {balance_val:.2f} credits | Frozen: {frozen_val:.2f} credits")

    if args.check_only:
        return

    if balance_val <= 0.0:
        print("\n⚠️ WARNING: Your Tripo3D account currently has 0.00 credits.")
        print("Tripo API requires credits to process 3D generation tasks (1 text-to-3D task = 100 credits).")
        print("👉 Please top up or claim developer credits at: https://developers.tripo3d.ai/en/billing")
        print("Once credited, run this script again to generate the model immediately!")
        sys.exit(2010)

    # 2. Task submission
    task_id = ""
    if args.mode == "image":
        if not args.image or not os.path.isfile(args.image):
            print(f"❌ Image file not found: {args.image}")
            sys.exit(1)
        print(f"Uploading image: {args.image}...")
        token = upload_file(args.api_key, args.image)
        print("Submitting image-to-model task...")
        task_id = create_image_to_model_task(args.api_key, token, model=args.model)
    else:
        print("Submitting text-to-model task...")
        print(f"Prompt: {args.prompt}")
        task_id = create_text_to_model_task(args.api_key, args.prompt, model=args.model)

    print(f"Task ID created: {task_id}")

    # 3. Polling
    task_data = poll_task(args.api_key, task_id)
    output = task_data.get("output", {})
    model_url = output.get("model_url")

    if not model_url:
        print(f"❌ No model_url in output: {output}")
        sys.exit(1)

    # 4. Download
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    download_file(model_url, args.output)

    # 5. Godot pipeline update
    print("\n🔄 Re-importing into Godot Engine pipeline...")
    os.system("cd /Users/cuong.le/Document/build-the-game && godot --headless --editor --quit")
    print("✨ Pipeline integration complete!")

if __name__ == "__main__":
    main()
