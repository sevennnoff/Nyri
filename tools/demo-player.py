#!/usr/bin/env python3
"""A stand-in MPRIS player for screenshots and demo videos.

    demo-player.py IDENTITY TITLE ARTIST [COVER.png] [LENGTH_S]

Registers org.mpris.MediaPlayer2.nyridemo on the session bus, "plays" from
a minute in, and honours play/pause/next/previous, so the shell's player
card behaves as with a real one. Runs until killed.
"""
import sys, time
from gi.repository import Gio, GLib

identity, title, artist = sys.argv[1:4]
cover = sys.argv[4] if len(sys.argv) > 4 else ""
length = int(sys.argv[5]) if len(sys.argv) > 5 else 187

XML = """<node>
<interface name="org.mpris.MediaPlayer2">
  <property name="Identity" type="s" access="read"/>
  <property name="CanRaise" type="b" access="read"/>
  <property name="CanQuit" type="b" access="read"/>
</interface>
<interface name="org.mpris.MediaPlayer2.Player">
  <method name="PlayPause"/><method name="Play"/><method name="Pause"/>
  <method name="Next"/><method name="Previous"/>
  <method name="Seek"><arg type="x" direction="in"/></method>
  <method name="SetPosition"><arg type="o" direction="in"/><arg type="x" direction="in"/></method>
  <property name="PlaybackStatus" type="s" access="read"/>
  <property name="Metadata" type="a{sv}" access="read"/>
  <property name="Position" type="x" access="read"/>
  <property name="CanPlay" type="b" access="read"/><property name="CanPause" type="b" access="read"/>
  <property name="CanGoNext" type="b" access="read"/><property name="CanGoPrevious" type="b" access="read"/>
  <property name="CanSeek" type="b" access="read"/><property name="CanControl" type="b" access="read"/>
</interface></node>"""

state = {"playing": True, "start": time.time() - 64, "paused_at": 0.0}


def pos():
    t = state["paused_at"] if not state["playing"] else time.time() - state["start"]
    return int(min(t, length) * 1e6)


def metadata():
    return GLib.Variant("a{sv}", {
        "mpris:trackid": GLib.Variant("o", "/nyri/demo/track/1"),
        "mpris:length": GLib.Variant("x", length * 10**6),
        "xesam:title": GLib.Variant("s", title),
        "xesam:artist": GLib.Variant("as", [artist]),
        **({"mpris:artUrl": GLib.Variant("s", "file://" + cover)} if cover else {}),
    })


def props():
    return {
        "Identity": GLib.Variant("s", identity), "CanRaise": GLib.Variant("b", False), "CanQuit": GLib.Variant("b", False),
        "PlaybackStatus": GLib.Variant("s", "Playing" if state["playing"] else "Paused"),
        "Metadata": metadata(),
        "Position": GLib.Variant("x", pos()),
        **{k: GLib.Variant("b", True) for k in ("CanPlay", "CanPause", "CanGoNext", "CanGoPrevious", "CanSeek", "CanControl")},
    }


def changed(conn, names):
    conn.emit_signal(None, "/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties", "PropertiesChanged",
                     GLib.Variant("(sa{sv}as)", ("org.mpris.MediaPlayer2.Player", {n: props()[n] for n in names}, [])))


def call(conn, sender, path, iface, method, params, inv):
    if method in ("PlayPause", "Play", "Pause"):
        want = (not state["playing"]) if method == "PlayPause" else method == "Play"
        if want and not state["playing"]:
            state["start"] = time.time() - state["paused_at"]
        elif not want and state["playing"]:
            state["paused_at"] = time.time() - state["start"]
        state["playing"] = want
        changed(conn, ["PlaybackStatus"])
    elif method in ("Next", "Previous"):
        state["start"] = time.time()
        changed(conn, ["Metadata"])
    inv.return_value(None)


def get(conn, sender, path, iface, name):
    return props()[name]


bus = Gio.bus_get_sync(Gio.BusType.SESSION)
for i in Gio.DBusNodeInfo.new_for_xml(XML).interfaces:
    bus.register_object("/org/mpris/MediaPlayer2", i, call, get, None)
Gio.bus_own_name_on_connection(bus, "org.mpris.MediaPlayer2.nyridemo", Gio.BusNameOwnerFlags.NONE, None, None)
GLib.MainLoop().run()
