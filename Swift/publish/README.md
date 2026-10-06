# Publish

Publish 0.9.0 (JohnSundell/Publish, with Ink 0.6.0 and Plot 0.14.0) on Swift 6.4.0, Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/Content/posts`, then times `.build/release/SSGBerk`, the site executable compiled at image build time (multi-stage: the Swift toolchain stays in the builder stage, only the binary and the Swift runtime shared libraries reach the final image). Each post must render to `Output/posts/*/index.html`; the verification step checks the count equals the requested number of files. Run it with `./ssgberk --test publish -nf 10`.

Deviations:
- A custom publishing step reads `Content/posts/*.md` (Ink's metadata block rejects the YAML `tags:` list of the shared `3minus` front matter) and builds items with Ink for the body; the theme is a custom `HTMLFactory` (no tag pages, RSS or sitemap steps).
- `--static-swift-stdlib` fails to link on Swift 6.4 (ICU symbols), so the binary is dynamic and the final image carries `/usr/lib/swift/linux/*.so`.
- Cache folder: `.publish` (Publish writes `Caches` and `lastGenerationDate` there).
- Ink does not support `~~~` code fences, so those blocks render as plain text in the output (the build is unaffected).
