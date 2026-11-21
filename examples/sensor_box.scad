// A small sealed box for a sensor board, one cable gland, held shut by hex nuts
include <../enclosure.scad>

length = 50;
width = 70;
height = 35;
lid_height = 10;
nut = "hex nut";
head = "counterbored";
// One M12 gland in the short wall at -y
glands_b = 1;
// A board with holes 30 x 50 mm apart
board = true;
board_spacing = [30, 50];
