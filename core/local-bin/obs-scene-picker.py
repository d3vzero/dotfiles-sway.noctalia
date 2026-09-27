#!/usr/bin/env python3
import subprocess
import sys
import time

PASSWORD_FILE = "/home/DrDDrake/.config/obs-tools/password"


def get_password():
    try:
        with open(PASSWORD_FILE) as f:
            return f.read().strip()
    except FileNotFoundError:
        return ""


try:
    import obsws_python as obs
except ImportError:
    subprocess.run(["notify-send", "-u", "critical", "OBS Scene Picker",
                     "obsws_python belum terpasang. Jalankan: pip install --user obsws-python --break-system-packages"])
    sys.exit(1)


def obs_running():
    return subprocess.run(["pgrep", "-x", "obs"], capture_output=True).returncode == 0


if not obs_running():
    subprocess.Popen(["obs"], start_new_session=True)
    subprocess.run(["notify-send", "OBS", "Membuka OBS..."])


def connect(retries=20, delay=0.5):
    last_err = None
    for _ in range(retries):
        try:
            return obs.ReqClient(host="localhost", port=4455, password=get_password(), timeout=2)
        except Exception as e:
            last_err = e
            time.sleep(delay)
    raise last_err


try:
    cl = connect()
except Exception as e:
    subprocess.run(["notify-send", "-u", "critical", "OBS Scene Picker", f"Gagal konek ke OBS WebSocket: {e}"])
    sys.exit(1)

resp = cl.get_scene_list()
scenes = [s["sceneName"] for s in resp.scenes]
scenes.reverse()

result = subprocess.run(
    ["fuzzel", "--dmenu", "--no-exit-on-keyboard-focus-loss", "--prompt", "Scene: "],
    input="\n".join(scenes), capture_output=True, text=True
)
choice = result.stdout.strip()
if choice and choice in scenes:
    cl.set_current_program_scene(choice)
    subprocess.run(["notify-send", "OBS", f"Scene: {choice}"])
