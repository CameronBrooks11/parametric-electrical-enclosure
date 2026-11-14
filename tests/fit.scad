// The seal, checked by intersection. CHECK picks one:
//   "seated"  the bottom against the lid seated on it, the lid moved DX along x
//   "gasket"  the gasket in its groove against the seated lid
// Each should be empty (no overlap) or as tall as the checks expect.
include <../enclosure.scad>

part = "none";
gasket = false;
CHECK = "seated";
DX = 0;

module seated_lid() translate([DX, 0, height]) mirror([0, 0, 1]) lid();

if (CHECK == "seated") intersection() { bottom(); seated_lid(); }
else if (CHECK == "gasket") intersection() {
  translate([0, 0, bottom_h - groove_full]) gasket_part();
  seated_lid();
}
