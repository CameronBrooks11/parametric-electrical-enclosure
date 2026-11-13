default:
    @just --list

# Render each part of the case at a few sizes and check its pieces and size
test:
    python3 tests/test_case.py
