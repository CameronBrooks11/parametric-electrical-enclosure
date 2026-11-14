"""Render the enclosure's parts and check their pieces, sizes and seal.

usage: python3 tests/test_case.py [OPENSCAD]

Each render uses --hardwarnings and $fn = 40. A binary STL's separate solids
are counted (triangles sharing a vertex belong to the same solid) and its size
checked to within 0.01 mm. A render OpenSCAD reports as empty counts as no
overlap, which is what the seal checks expect.
"""

import os
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CASE = os.path.join(ROOT, "enclosure.scad")
FIT = os.path.join(ROOT, "tests", "fit.scad")
PRESETS = os.path.join(ROOT, "enclosure.json")


def measure(path):
    data = open(path, "rb").read()
    (n,) = struct.unpack_from("<I", data, 80)
    parent = {}

    def find(v):
        while parent[v] != v:
            parent[v] = parent[parent[v]]
            v = parent[v]
        return v

    for i in range(n):
        v = struct.unpack_from("<9f", data, 84 + i * 50 + 12)
        corners = [v[0:3], v[3:6], v[6:9]]
        for c in corners:
            parent.setdefault(c, c)
        root = find(corners[0])
        for c in corners[1:]:
            parent[find(c)] = root
    solids = len({find(v) for v in parent})
    size = [max(p[i] for p in parent) - min(p[i] for p in parent) for i in range(3)]
    return solids, size


def render(openscad, scad, out, defines, preset=None):
    """(solids, size), or None when OpenSCAD reports empty geometry."""
    cmd = [openscad, "--hardwarnings", "--export-format", "binstl", "-o", out, "-D", "$fn=40"]
    if preset:
        cmd += ["-p", PRESETS, "-P", preset]
    for name, value in defines.items():
        cmd += ["-D", f"{name}={value}"]
    result = subprocess.run(cmd + [scad], capture_output=True, text=True)
    if "empty" in result.stderr.lower():
        return None
    if result.returncode != 0:
        errors = [l for l in result.stderr.splitlines() if "WARNING" in l or "ERROR" in l]
        raise RuntimeError(f"openscad exited {result.returncode}: {'; '.join(errors)}")
    return measure(out)


def part(name):
    return {"part": f'"{name}"'}


# The lid stands ridge_h = groove_depth - fit = 1.7 mm taller than lid_height, and
# the gasket is gasket_height + 2 * fit = 2.1 mm thick. Assembled (gasket left
# out), the parts are two pieces: the lid is 0.05 mm above the bottom's rim.
NO_GASKET = {"gasket": "false"}
CASES = [
    # (label, defines, preset, solids, x, y, z)
    ("bottom", part("bottom"), None, 1, 60, 100, 30),
    ("lid", part("lid"), None, 1, 60, 100, 11.7),
    ("gasket", part("gasket"), None, 1, 58.1, 98.1, 2.1),
    ("assembled", {**part("assembled"), **NO_GASKET}, None, 2, 60, 100, 40.05),
    ("bottom, hex nuts and counterbored heads",
     {**part("bottom"), "nut": '"hex nut"', "head": '"counterbored"'}, None, 1, 60, 100, 30),
    ("lid, counterbored heads", {**part("lid"), "head": '"counterbored"'}, None, 1, 60, 100, 11.7),
]
for length, width, height, lid in ((120, 80, 50, 15), (80, 80, 30, 8)):
    size = {"length": length, "width": width, "height": height, "lid_height": lid}
    CASES.append((f"bottom {length} x {width} x {height}, lid {lid}", {**part("bottom"), **size},
                  None, 1, length, width, height - lid))
    CASES.append((f"assembled {length} x {width} x {height}, lid {lid}",
                  {**part("assembled"), **size, **NO_GASKET}, None, 2, length, width, height + 0.05))

WALL = "Wall-mounted, two cable glands and a board"
LARGE = "Large, with extra screws on both sides"
CASES += [
    # The flanges reach 15 mm past both ends: 140 + 2 * 15.
    (f"preset {WALL}, bottom", part("bottom"), WALL, 1, 100, 170, 40),
    (f"preset {WALL}, assembled", {**part("assembled"), **NO_GASKET}, WALL, 2, 100, 170, 50.05),
    (f"preset {LARGE}, bottom", part("bottom"), LARGE, 1, 200, 150, 40),
    (f"preset {LARGE}, assembled", {**part("assembled"), **NO_GASKET}, LARGE, 2, 200, 150, 60.05),
]

# The seal: seated, the lid only touches the bottom, and its ridge sits in the
# groove with fit (0.3 mm) of clearance each side, so moving the lid 0.25 mm
# sideways still clears and 0.35 mm runs the ridge into the groove's wall. The
# gasket stands fit proud of where the seated ridge stops, so they overlap by
# exactly fit.
SEAL = [
    # (label, defines, overlap height or None for no overlap)
    ("seated", {"CHECK": '"seated"'}, None),
    ("seated, lid moved 0.25 mm", {"CHECK": '"seated"', "DX": 0.25}, None),
    ("seated, lid moved 0.35 mm", {"CHECK": '"seated"', "DX": 0.35}, "any"),
    ("the ridge presses the gasket", {"CHECK": '"gasket"', "gasket": "true"}, 0.3),
]


def main():
    openscad = sys.argv[1] if len(sys.argv) > 1 else "openscad"
    failed = 0
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "case.stl")
        for label, defines, preset, want_solids, *want_size in CASES:
            got = render(openscad, CASE, out, defines, preset)
            ok = got is not None and got[0] == want_solids and all(
                abs(a - b) <= 0.01 for a, b in zip(got[1], want_size))
            line = "empty" if got is None else f"{got[0]} solids, {' x '.join(f'{s:.2f}' for s in got[1])} mm"
            if not ok:
                failed += 1
                line += f"; expected {want_solids} solids, {' x '.join(f'{s:.2f}' for s in want_size)} mm"
            print(f"{'ok  ' if ok else 'FAIL'} {label}: {line}")
        for label, defines, want in SEAL:
            got = render(openscad, FIT, out, defines)
            if want is None:
                # Faces that only touch leave a zero-height sliver, not an overlap.
                ok = got is None or got[1][2] <= 0.001
            elif want == "any":
                ok = got is not None
            else:
                ok = got is not None and abs(got[1][2] - want) <= 0.01
            line = "no overlap" if got is None else f"overlap {got[1][2]:.2f} mm tall"
            if not ok:
                failed += 1
            print(f"{'ok  ' if ok else 'FAIL'} seal, {label}: {line}")
    total = len(CASES) + len(SEAL)
    print(f"{total - failed} of {total} checks passed")
    sys.exit(1 if failed else 0)


main()
