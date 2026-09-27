#!/usr/bin/env python3
import sys

PASSWORD_FILE = "/home/DrDDrake/.config/obs-tools/password"
SOURCE_NAME = "Screen Capture (PipeWire)"
RECORD_FPS = 60          # fixed, tidak ikut refresh rate monitor (300Hz dkk)
TARGET_WIDTH = 1920      # output/scaled tetap, 16:10
TARGET_HEIGHT = 1200


def get_password():
    try:
        with open(PASSWORD_FILE) as f:
            return f.read().strip()
    except FileNotFoundError:
        return ""


try:
    import obsws_python as obs
except ImportError:
    sys.exit(0)

if len(sys.argv) != 4:
    sys.exit(1)

width, height, _monitor_fps = int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3])

# Jangan pernah upscale -- kalau base lebih kecil dari target (misal pilih
# resolusi monitor rendah), output ikut base apa adanya.
out_width = min(TARGET_WIDTH, width)
out_height = min(TARGET_HEIGHT, height)

try:
    cl = obs.ReqClient(host="localhost", port=4455, password=get_password(), timeout=2)

    cl.send("SetVideoSettings", {
        "baseWidth": width, "baseHeight": height,
        "outputWidth": out_width, "outputHeight": out_height,
        "fpsNumerator": RECORD_FPS, "fpsDenominator": 1,
    })

    scene = cl.get_current_program_scene().current_program_scene_name
    item_resp = cl.send("GetSceneItemId", {"sceneName": scene, "sourceName": SOURCE_NAME})
    item_id = item_resp.scene_item_id

    cl.send("SetSceneItemTransform", {
        "sceneName": scene,
        "sceneItemId": item_id,
        "sceneItemTransform": {
            "positionX": 0,
            "positionY": 0,
            "boundsType": "OBS_BOUNDS_STRETCH",
            "boundsAlignment": 0,
            "boundsWidth": width,
            "boundsHeight": height,
            "alignment": 5,
        },
    })
except Exception:
    pass
