"""Render the case's parts and check each one's pieces and size.

usage: python3 tests/test_case.py [OPENSCAD]

Each render uses --hardwarnings and $fn = 40 to stay quick. A binary STL's
separate solids are counted (triangles sharing a vertex belong to the same
solid), and sizes are checked to within 0.01 mm.
"""

import os
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CASE = os.path.join(ROOT, "ultimatewaterproofcase.scad")


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


BOTTOM = {"ShowTop": "false", "ShowGasket": "false"}
TOP = {"ShowBottom": "false", "ShowGasket": "false"}
GASKET = {"ShowBottom": "false", "ShowTop": "false"}
ASSEMBLED = {"ShowCaseAssembled": "true", "ShowGasket": "false"}

# The bottom is CaseHeight - CutFromTop tall plus the 1.7 mm ridge, less the
# 0.01 mm it sits into the rim. Assembled, the bottom and lid are two pieces:
# the ridge doesn't reach the lid.
CASES = [
    ("bottom", BOTTOM, 1, 60, 100, 31.71),
    ("top", TOP, 1, 60, 100, 10),
    ("gasket", GASKET, 1, 58.08, 98.08, 1.5),
    ("assembled", ASSEMBLED, 2, 60, 100, 40.03),
]
for length, width, height, cut in ((120, 80, 50, 15), (80, 80, 30, 8)):
    size = {"Caselength": length, "CaseWidth": width, "CaseHeight": height, "CutFromTop": cut}
    CASES.append((f"bottom {length} x {width} x {height}, cut {cut}", {**BOTTOM, **size},
                  1, length, width, height - cut + 1.71))
    CASES.append((f"assembled {length} x {width} x {height}, cut {cut}", {**ASSEMBLED, **size},
                  2, length, width, height + 0.03))


def main():
    openscad = sys.argv[1] if len(sys.argv) > 1 else "openscad"
    failed = 0
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "case.stl")
        for label, defines, want_solids, *want_size in CASES:
            cmd = [openscad, "--hardwarnings", "--export-format", "binstl", "-o", out, "-D", "$fn=40"]
            for name, value in defines.items():
                cmd += ["-D", f"{name}={value}"]
            result = subprocess.run(cmd + [CASE], capture_output=True, text=True)
            if result.returncode != 0:
                failed += 1
                errors = [l for l in result.stderr.splitlines() if "WARNING" in l or "ERROR" in l]
                print(f"FAIL {label}: openscad exited {result.returncode}: {'; '.join(errors)}")
                continue
            solids, size = measure(out)
            ok = solids == want_solids and all(abs(a - b) <= 0.01 for a, b in zip(size, want_size))
            got = f"{solids} solids, {' x '.join(f'{s:.2f}' for s in size)} mm"
            if not ok:
                failed += 1
                got += f"; expected {want_solids} solids, {' x '.join(f'{s:.2f}' for s in want_size)} mm"
            print(f"{'ok  ' if ok else 'FAIL'} {label}: {got}")
    print(f"{len(CASES) - failed} of {len(CASES)} cases passed")
    sys.exit(1 if failed else 0)


main()
