#!/usr/bin/env python3
"""Remember kanata's mode (base = home-row mods, plain = normal keyboard) per app.

  kanata-modes.py            run the daemon (kanata-modes.service)
  kanata-modes.py focus APP  tell the daemon which app is focused (the panel's
                             System Stats widget calls this on focus changes)

The daemon talks to kanata over its local TCP port (kanata -p 127.0.0.1:5829):
  - you hold Esc to switch modes -> saved for the focused app + on-screen message
  - an app gets focus            -> its saved mode is restored (default: base)
  - KDE's "disable touchpad while typing" is on in home-row mode and off in
    plain mode (gaming); your own setting is put back when this stops

Linux/KDE only. Standard library only.
"""
import ast
import json
import os
import select
import signal
import socket
import subprocess
import sys
import time

KANATA = ("127.0.0.1", 5829)
MODES = ("base", "plain")
STATE = os.path.expanduser("~/.local/state/kanata-modes.json")
SOCK = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "kanata-modes.sock")


def osd(text):
    subprocess.Popen(["qdbus6", "org.kde.plasmashell", "/org/kde/osdService",
                      "org.kde.osdService.showText", "input-keyboard", text],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def kwin_device(dev, prop):
    out = subprocess.run(
        ["gdbus", "call", "--session", "--dest", "org.kde.KWin",
         "--object-path", "/org/kde/KWin/InputDevice" + (f"/{dev}" if dev else ""),
         "--method", "org.freedesktop.DBus.Properties.Get",
         "org.kde.KWin.InputDevice" + ("" if dev else "Manager"), prop],
        capture_output=True, text=True).stdout.strip()
    # gdbus prints e.g. (<'ASUP1208:00 Touchpad'>,) or (<true>,)
    out = out[2:-3] if out.startswith("(<") else ""
    return {"true": True, "false": False}.get(out, out.strip("'"))


def touchpads():
    try:
        devs = ast.literal_eval(kwin_device(None, "devicesSysNames"))
    except (ValueError, SyntaxError):
        return []
    return [d for d in devs if kwin_device(d, "touchpad") and kwin_device(d, "supportsDisableWhileTyping")]


def set_typing_guard(on):
    """KDE's "disable touchpad while typing", for every touchpad."""
    for dev in touchpads():
        subprocess.run(["gdbus", "call", "--session", "--dest", "org.kde.KWin",
                        "--object-path", f"/org/kde/KWin/InputDevice/{dev}",
                        "--method", "org.freedesktop.DBus.Properties.Set",
                        "org.kde.KWin.InputDevice", "disableWhileTyping", f"<{str(on).lower()}>"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def label(mode, app):
    name = "Plain keyboard" if mode == "plain" else "Home-row mods"
    return name + (f" · {app}" if app else "")


def load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save(modes):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE, "w") as f:
        json.dump(modes, f, indent=2, sort_keys=True)


def connect_kanata():
    while True:
        try:
            s = socket.create_connection(KANATA, timeout=2)
            s.settimeout(None)
            s.sendall(b'{"RequestCurrentLayerName":{}}\n')
            return s
        except OSError:
            time.sleep(2)


def daemon():
    modes = load()
    app, layer = None, "base"

    try:
        os.unlink(SOCK)
    except FileNotFoundError:
        pass
    server = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    server.bind(SOCK)

    pads = touchpads()
    original = kwin_device(pads[0], "disableWhileTyping") if pads else True

    def stop(*_):
        set_typing_guard(original)
        sys.exit(0)
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    kanata = connect_kanata()
    set_typing_guard(layer == "base")
    buf = b""

    def set_layer(name):
        kanata.sendall(json.dumps({"ChangeLayer": {"new": name}}).encode() + b"\n")

    while True:
        ready, _, _ = select.select([kanata, server], [], [])

        if server in ready:
            app = server.recv(4096).decode(errors="replace").strip() or None
            want = modes.get(app, "base")
            if want != layer:
                set_layer(want)
                layer = want  # kanata echoes this back; it's ignored as a repeat
                set_typing_guard(want == "base")
                osd(label(want, app))

        if kanata in ready:
            data = kanata.recv(4096)
            if not data:  # kanata restarted
                kanata.close()
                kanata, buf = connect_kanata(), b""
                continue
            buf += data
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                try:
                    msg = json.loads(line)
                except ValueError:
                    continue
                new = (msg.get("LayerChange") or {}).get("new") or \
                      (msg.get("CurrentLayerName") or {}).get("name")
                if new not in MODES or new == layer:
                    continue  # ignore nav (space held) and repeats
                layer = new
                set_typing_guard(new == "base")
                if "CurrentLayerName" in msg:
                    continue  # just the starting state
                if app:  # you held Esc: remember it for this app
                    if new == "base":
                        modes.pop(app, None)
                    else:
                        modes[app] = new
                    save(modes)
                osd(label(new, app))


def focus(app):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    try:
        s.sendto(app.encode(), SOCK)
    except OSError:
        pass  # daemon not running


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "focus":
        focus(sys.argv[2])
    else:
        daemon()
