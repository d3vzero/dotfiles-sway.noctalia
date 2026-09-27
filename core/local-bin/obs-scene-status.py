#!/usr/bin/env python3
import sys

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
    print("OFF|0")
    sys.exit(0)

try:
    cl = obs.ReqClient(host="localhost", port=4455, password=get_password(), timeout=2)
    scene = cl.get_current_program_scene().current_program_scene_name
    rec = cl.get_record_status().output_active
    print(f"{scene}|{'1' if rec else '0'}")
except Exception:
    print("OFF|0")
