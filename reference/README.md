# Reference assets and HTML

Canonical shared files for the SSGBerk reference site (spec `docs/specs/005-reference-site-design`). The literal content is defined in that spec's `plan.md`.

- `assets/ssgberk.css`: the reference stylesheet. Copied verbatim by every generator, never processed.
- `assets/ssgberk.png`: 64x64 RGB image, four horizontal bands. Produced once by `tools/make_reference_png.py` and committed. Copies come from this file, not from re-running the script.
- `html/post.html`: reference output for post 1 (N=3, `-cs 0.500`).
- `html/index.html`: reference output for the index with 3 posts.
- `html/404.html`: reference output for the 404 page.

`html/*` is the golden input for the conformance checker tests (`docs/specs/006-layout-conformance`). Copies of `assets/*` in each generator's static folder must stay byte-identical to these files.

Tests: `python3 -m unittest tests/reference/test_reference.py -v`
