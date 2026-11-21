default:
    @just --list

# Render each part of the case at a few sizes and check its pieces and size
test:
    python3 tests/test_case.py

# Everything CI runs, bar the tests
check: fmt-check

# Format the .scad sources with topiary (.topiary/languages.ncl)
fmt:
    git ls-files -z '*.scad' | xargs -0 -r topiary format

# Check the .scad sources are formatted, without changing them
fmt-check:
    git ls-files -z '*.scad' | xargs -0 -r -n1 topiary format --check

# Render the README pictures into assets/
images:
    @mkdir -p assets
    openscad --render --colorscheme=Tomorrow --imgsize=600,450 --viewall --autocenter --camera=0,0,0,55,0,30,0 -D '$fn=80' -D 'part="all"' -o assets/parts.png enclosure.scad
    openscad --render --colorscheme=Tomorrow --imgsize=600,450 --viewall --autocenter --camera=0,0,0,60,0,30,0 -D '$fn=80' -D 'part="assembled"' -D gasket=false -o assets/assembled.png enclosure.scad
    openscad --render --colorscheme=Tomorrow --imgsize=600,450 --viewall --autocenter --camera=0,0,0,70,0,20,0 -D '$fn=80' -D 'part="section"' -o assets/section.png enclosure.scad
    openscad --render --colorscheme=Tomorrow --imgsize=600,450 --viewall --autocenter --camera=0,0,0,50,0,35,0 -D '$fn=80' -D 'part="bottom"' -p enclosure.json -P 'Wall-mounted, two cable glands and a board' -o assets/features.png enclosure.scad
