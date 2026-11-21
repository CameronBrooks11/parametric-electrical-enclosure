// enclosure.scad: a parametric, waterproof enclosure for electronics.
//
// A bottom and a lid with a groove-and-ridge seal (and an optional printed gasket),
// screwed together through pillars at the corners, with optional cable-gland holes,
// board standoffs and wall-mount flanges. Every part prints without supports.
// MIT licence; see LICENSE.

/* [View] */
// What to draw: one part for export, all three laid out, assembled, or cut in half
part = "all"; // [all, bottom, lid, gasket, assembled, section, none]

/* [Case] */
// Outside length, along x (mm)
length = 60; // [30:1:300]
// Outside width, along y (mm)
width = 100; // [30:1:300]
// Outside height of the closed case (mm)
height = 40; // [15:1:200]
// Height of the lid, from the top down to the split (mm)
lid_height = 10; // [5:1:100]
// Side walls (mm)
wall = 3.2; // [2:0.1:8]
// Floor of the bottom and top of the lid (mm)
floor_thickness = 3; // [1.2:0.2:8]
// Radius of the case's vertical corners (mm)
corner_radius = 10; // [4:0.5:30]

/* [Seal] */
// Width of the groove in the bottom's rim (mm)
groove_width = 1.6; // [0.8:0.1:3]
// Depth of the groove (mm)
groove_depth = 2; // [1:0.1:5]
// Clearance between the lid's ridge and the groove, on each side (mm)
fit = 0.3; // [0.1:0.05:0.6]
// A gasket in the groove, printed in TPU; the groove is deepened to hold it
gasket = true;
// Thickness of the gasket (mm)
gasket_height = 1.5; // [0.8:0.1:4]

/* [Screws] */
// Screw size: M2 to M5
screw = 3; // [2, 2.5, 3, 4, 5]
// Screw heads sit flush in the lid
head = "countersunk"; // [countersunk, counterbored]
// What the screws go into in the bottom
nut = "insert"; // [insert, hex nut]
// Add a screw midway along each side, for large cases
extra_screws = false;

/* [Cable glands] */
// Hole diameter, for the gland's thread (mm): 12.5 fits M12
gland_diameter = 12.5; // [3:0.5:30]
// Height of the holes' centres above the floor (mm)
gland_height = 10; // [3:0.5:100]
// Holes in wall A, at +x
glands_a = 0; // [0:3]
// Holes in wall B, at -y
glands_b = 0; // [0:3]
// Holes in wall C, at -x
glands_c = 0; // [0:3]
// Holes in wall D, at +y
glands_d = 0; // [0:3]

/* [Board standoffs] */
// Four standoffs on the floor, for a board
board = false;
// Distance between the board's holes, along x and y (mm)
board_spacing = [50, 70];
// Move the standoffs off centre, along x and y (mm)
board_offset = [0, 0];
// Standoff height above the floor (mm)
standoff_height = 5; // [2:0.5:30]
// Standoff diameter (mm)
standoff_diameter = 6; // [3:0.5:12]
// Hole in each standoff, for a self-tapping screw (mm)
standoff_hole = 2.5; // [1:0.1:5]

/* [Wall mount] */
// Flanges at both ends of the bottom, to screw the case to a wall
wall_mount = false;
// How far each flange sticks out past the case (mm)
flange_length = 15; // [8:1:40]
// Flange thickness (mm)
flange_thickness = 4; // [2:0.5:10]
// Holes per flange
flange_holes = 2; // [1:3]
// Hole diameter (mm)
flange_hole_diameter = 4.5; // [2:0.5:10]

/* [Hidden] */
$fn = $preview ? 48 : 96;
EPS = 0.01;

// ---------------- Derived sizes ----------------

bottom_h = height - lid_height;
groove_full = groove_depth + (gasket ? gasket_height : 0);
ridge_w = groove_width - 2 * fit;
ridge_h = groove_depth - fit;
// Each part's walls are hollow down to the floor or up to the lid's top.
inner = [length - 2 * wall, width - 2 * wall];
inner_r = max(corner_radius - wall, 1);

// Screws: [size, clearance hole, countersunk head diameter, counterbore diameter,
// counterbore depth, heat-set insert hole, insert depth, hex nut across flats, nut height]
SCREWS = [
    [2, 2.4, 4.0, 4.2, 2.0, 3.2, 4.0, 4.0, 1.6],
    [2.5, 2.9, 5.0, 5.0, 2.5, 3.6, 5.0, 5.0, 2.0],
    [3, 3.4, 6.0, 6.0, 3.0, 4.0, 5.7, 5.5, 2.4],
    [4, 4.5, 8.0, 7.6, 4.0, 5.6, 8.1, 7.0, 3.2],
    [5, 5.5, 10.0, 9.2, 5.0, 6.4, 9.5, 8.0, 4.0],
];
S = [for (s = SCREWS) if (s[0] == screw) s][0];
assert(!is_undef(S), str("screw must be 2, 2.5, 3, 4 or 5, not ", screw));
pillar_r = max(S[5], S[7] / cos(30)) / 2 + 1.6;
// A pillar's centre, in from the outside: clear of the wall and of the groove.
pillar_in = wall + pillar_r - 0.6;
head_depth = head == "countersunk" ? S[2] / 2 : S[4];
// The lid's pillar from the top down to the split, less the head's recess; the screw
// reaches on into the bottom by the insert's depth, or through the nut.
engaged = nut == "insert" ? S[6] : bottom_h - floor_thickness / 2;
screw_len = lid_height - head_depth + min(engaged, 3 * screw);

assert(lid_height > floor_thickness + 2, "lid_height must leave room for the lid's walls");
assert(bottom_h > floor_thickness + groove_full + 2, "the case is too shallow for its floor and groove");
assert(wall >= groove_width + 1.2, str("wall must be at least groove_width + 1.2 (", groove_width + 1.2, ") so the groove has walls"));
assert(corner_radius > wall, "corner_radius must be more than wall");

function pillars() =
    concat(
        [for (sx = [-1, 1], sy = [-1, 1]) [sx * (length / 2 - pillar_in), sy * (width / 2 - pillar_in)]],
        extra_screws ? [
                [0, -(width / 2 - pillar_in)],
                [0, width / 2 - pillar_in],
                [-(length / 2 - pillar_in), 0],
                [length / 2 - pillar_in, 0],
            ]
        : []
    );

// ---------------- 2D outlines ----------------

module rounded(size, r) {
    offset(r=r) square([size[0] - 2 * r, size[1] - 2 * r], center=true);
}
module outline() rounded([length, width], corner_radius);
module cavity() rounded(inner, inner_r);
// The groove's (or ridge's) footprint: a band of width w along the middle of the wall.
module seal_band(w) {
    difference() {
        offset(delta=-(wall - w) / 2) outline();
        offset(delta=-(wall + w) / 2) outline();
    }
}

// ---------------- The bottom ----------------

module bottom() {
    difference() {
        union() {
            difference() {
                linear_extrude(bottom_h) outline();
                translate([0, 0, floor_thickness]) linear_extrude(bottom_h) cavity();
            }
            for (p = pillars()) translate([p[0], p[1], 0]) cylinder(r=pillar_r, h=bottom_h);
            if (board)
                for (sx = [-1, 1], sy = [-1, 1])
                    translate([board_offset[0] + sx * board_spacing[0] / 2, board_offset[1] + sy * board_spacing[1] / 2, 0])
                        cylinder(d=standoff_diameter, h=floor_thickness + standoff_height);
            if (wall_mount) flanges();
        }
        // The groove, from the rim down.
        translate([0, 0, bottom_h - groove_full]) linear_extrude(groove_full + 1) seal_band(groove_width);
        // Screw holes: an insert's hole from the rim down, or a clearance hole right
        // through with a hex pocket for the nut from underneath.
        for (p = pillars())
            translate([p[0], p[1], 0]) {
                if (nut == "insert")
                    translate([0, 0, bottom_h - S[6]]) cylinder(d=S[5], h=S[6] + 1);
                else {
                    translate([0, 0, -1]) cylinder(d=S[1], h=bottom_h + 2);
                    translate([0, 0, -1]) cylinder(d=S[7] / cos(30) + 0.3, h=S[8] + 1.2, $fn=6);
                }
            }
        if (board)
            for (sx = [-1, 1], sy = [-1, 1])
                translate([board_offset[0] + sx * board_spacing[0] / 2, board_offset[1] + sy * board_spacing[1] / 2, floor_thickness])
                    cylinder(d=standoff_hole, h=standoff_height + 1);
        glands();
    }
}

// Gland holes: through each wall, spread evenly along it, gland_height above the floor.
module glands() {
    z = floor_thickness + gland_height;
    module along(n, span)for (i = [0:n - 1]) translate([0, (i - (n - 1) / 2) * span / max(n, 1), 0]) children();
    // [count, wall's centre, rotation, usable span]
    for (
        w = [
            [glands_a, [length / 2, 0], 0, width - 2 * corner_radius],
            [glands_b, [0, -width / 2], -90, length - 2 * corner_radius],
            [glands_c, [-length / 2, 0], 180, width - 2 * corner_radius],
            [glands_d, [0, width / 2], 90, length - 2 * corner_radius],
        ]
    )
        if (w[0] > 0)
            translate([w[1][0], w[1][1], z]) rotate(w[2])
                    along(w[0], w[3]) rotate([0, 90, 0]) cylinder(d=gland_diameter, h=3 * wall, center=true);
}

// Flanges past both ends (along y), on the floor, with holes for wall screws.
module flanges() {
    for (sy = [-1, 1])
        difference() {
            hull() {
                translate([0, sy * width / 2 * 0.5, 0]) linear_extrude(flange_thickness) square([length - 2 * corner_radius, width / 2], center=true);
                for (sx = [-1, 1])
                    translate([sx * (length / 2 - corner_radius), sy * (width / 2 + flange_length - 5), 0])
                        cylinder(r=5, h=flange_thickness);
            }
            for (i = [0:flange_holes - 1])
                translate(
                    [
                        (i - (flange_holes - 1) / 2) * (length - 2 * corner_radius) / max(flange_holes, 1),
                        sy * (width / 2 + flange_length / 2),
                        -1,
                    ]
                )
                    cylinder(d=flange_hole_diameter, h=flange_thickness + 2);
        }
}

// ---------------- The lid, drawn upside down: its top on z = 0 ----------------

module lid() {
    difference() {
        union() {
            difference() {
                linear_extrude(lid_height) outline();
                translate([0, 0, floor_thickness]) linear_extrude(lid_height) cavity();
            }
            for (p = pillars()) translate([p[0], p[1], 0]) cylinder(r=pillar_r, h=lid_height);
            // The ridge, standing up from the lid's rim into the groove.
            translate([0, 0, lid_height - EPS]) linear_extrude(ridge_h + EPS) seal_band(ridge_w);
        }
        for (p = pillars())
            translate([p[0], p[1], 0]) {
                translate([0, 0, -1]) cylinder(d=S[1], h=lid_height + 2);
                if (head == "countersunk")
                    translate([0, 0, -EPS]) cylinder(d1=S[2], d2=0, h=S[2] / 2);
                else
                    translate([0, 0, -1]) cylinder(d=S[3], h=S[4] + 1);
            }
    }
}

// The gasket: a ring in the groove's extra depth, standing 2 * fit proud of it, so the
// seated ridge (which stops fit short of that depth) presses it by fit.
module gasket_part() linear_extrude(gasket_height + 2 * fit) seal_band(groove_width - fit);

// ---------------- Assembly ----------------

// The lid turned over onto the bottom, its rim on the bottom's rim. A 0.05 mm gap keeps
// the parts separate in an export.
module assembled() {
    bottom();
    translate([0, 0, height + 0.05]) mirror([0, 0, 1]) lid();
    if (gasket) color("dimgray") translate([0, 0, bottom_h - groove_full]) gasket_part();
}

echo(
    str(
        "Case ", length, " x ", width, " x ", height, " mm outside, ",
        inner[0], " x ", inner[1], " x ", height - 2 * floor_thickness, " mm inside"
    )
);
echo(
    str(
        "Screws: ", len(pillars()), " x M", screw, ", at least ", ceil(screw_len), " mm long, ",
        head, ", into ", nut == "insert" ? "heat-set inserts" : "hex nuts"
    )
);

if (part == "bottom")
    bottom();
else if (part == "lid")
    lid();
else if (part == "gasket")
    gasket_part();
else if (part == "all") {
    bottom();
    translate([length + 10, 0, 0]) lid();
    if (gasket) translate([-length - 10, 0, 0]) gasket_part();
} else if (part == "assembled")
    assembled();
else if (part == "section")
    difference() {
        assembled();
        translate([0, -width, -1]) cube([length, 2 * width + 2 * flange_length, height + 2]);
    }
else
    assert(part == "none", str("unknown part ", part));
