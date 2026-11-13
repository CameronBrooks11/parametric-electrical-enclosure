default:
    @just --list

# Render each part of the case at a few sizes and check its pieces and size
test:
    python3 tests/test_case.py

# Render the README pictures into assets/
images:
    @mkdir -p assets
    openscad --render --colorscheme=Tomorrow --imgsize=600,450 --viewall --autocenter --camera=0,0,0,55,0,30,400 -D '$fn=80' -o assets/parts.png enclosure.scad
    openscad --render --colorscheme=Tomorrow --imgsize=600,450 --viewall --autocenter --camera=0,0,0,60,0,30,300 -D '$fn=80' -D ShowCaseAssembled=true -D ShowGasket=false -o assets/assembled.png enclosure.scad
    openscad --render --colorscheme=Tomorrow --imgsize=600,450 --viewall --autocenter --camera=0,0,0,60,0,30,300 -D '$fn=80' -D ShowCaseAssembled=true -D ShowGasket=false -D SeeGrooveRidgeScrew=true -o assets/section.png enclosure.scad
    openscad --render --colorscheme=Tomorrow --imgsize=600,450 --viewall --autocenter --camera=0,0,0,50,0,35,400 -D '$fn=80' -D ShowTop=false -D ShowGasket=false -p enclosure.json -P 'Wall-mounted, two cable glands and a board' -o assets/features.png enclosure.scad
