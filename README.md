# parametric-electrical-enclosure

A parametric, waterproof electronics case for 3D printing, made in OpenSCAD.
It's pbtec's
[Stable and waterproof OpenSCAD case](https://www.printables.com/model/72839-customizable-parametric-stable-and-waterproof-elec),
version 7.2, with one fix (below).

## Use it

Open `ultimatewaterproofcase.scad` in [OpenSCAD](https://openscad.org) and use
the Customizer panel. It sets:

- the case's outer size and where it splits into bottom and lid;
- the groove and ridge that seal the joint, with or without a sealing cord or a
  separate gasket for printing in TPU;
- corner screws (M2 to M5) with heat-set inserts, standard nuts or square nuts;
- wall-mount holders, holders for up to three circuit boards, holes in the
  floor, and up to three cable-gland holes on each side.

The console prints the inner and outer size and the screw length to buy.
`ShowBottom`, `ShowTop`, `ShowGasket` and `ShowCaseAssembled` choose what's
shown; export the bottom, lid and gasket separately. pbtec's notes are in the
header of the file: use 100 % infill for a waterproof case, and if you use
standard nuts, pause the print to insert them.

## Change from pbtec's version 7.2

The ridge on the bottom's rim sat 0.01 mm above the rim, so the bottom exported
as two separate bodies: the case and a floating ridge. It now sits 0.01 mm into
the rim, and the bottom is one piece. The lid is unchanged. The header's
version table records this as 7.2.1.

## Checks

`just test` takes about 1 s on OpenSCAD 2026.10.15. It renders the bottom,
lid, gasket and assembled case at the defaults and at two other sizes, and
checks each one's size and that the bottom is one piece and doesn't touch the
lid when assembled.

## Licence

pbtec licenses the case under
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/):
credit pbtec, no commercial use, and share changes under the same licence.
This copy keeps that licence; see [LICENSE](LICENSE). For pbtec's latest
version, see the Printables page.
