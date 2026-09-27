#!/usr/bin/env python3
"""Fit damped springs to multi-segment cubic Béziers for QML's BezierSpline.

QML's SpringAnimation steps at a fixed 16 ms (so it judders at 120 Hz) and
Behaviors cannot run custom physics, so the shell plays springs as curves:
the exact spring response x(t), sampled and joined with Hermite tangents,
lasting until it settles within 0.2%. Paste the output into theme/Motion.qml.

    tools/fit-springs.py            # prints { duration, curve } per token
"""
import math

TOKENS = {
    # name: (damping ratio, stiffness) — M3 Expressive, pushed a little
    # bouncier for default/slow than Compose's 0.8, on purpose.
    "fastSpatial": (0.6, 800),
    "defaultSpatial": (0.7, 420),
    "slowSpatial": (0.72, 240),
    "effects": (1.0, 1600),
}


def spring(z, k, eps=0.002):
    w0 = math.sqrt(k)
    if z < 1:
        wd = w0 * math.sqrt(1 - z * z)
        x = lambda t: 1 - math.exp(-z * w0 * t) * (math.cos(wd * t) + (z * w0 / wd) * math.sin(wd * t))
    else:
        x = lambda t: 1 - math.exp(-w0 * t) * (1 + w0 * t)
    dx = lambda t: (x(t + 1e-5) - x(t - 1e-5)) / 2e-5
    settle = max(i / 1000 for i in range(5000) if abs(x(i / 1000) - 1) > eps) + 0.02
    return x, dx, settle


def fit(z, k, segments=8):
    x, dx, T = spring(z, k)
    ts = [T * (i / segments) ** 1.3 for i in range(segments + 1)]
    out = []
    for i in range(segments):
        t0, t1 = ts[i], ts[i + 1]
        u0, u1 = t0 / T, t1 / T
        du = u1 - u0
        last = i == segments - 1
        y0, y1 = x(t0), 1.0 if last else x(t1)
        s0, s1 = dx(t0) * T, 0.0 if last else dx(t1) * T
        out += [u0 + du / 3, y0 + s0 * du / 3, u1 - du / 3, y1 - s1 * du / 3, u1, y1]
    return round(T * 1000), [round(v, 4) for v in out]


for name, (z, k) in TOKENS.items():
    ms, curve = fit(z, k)
    print(f"{name}: ({{ duration: {ms}, curve: {curve} }})")
