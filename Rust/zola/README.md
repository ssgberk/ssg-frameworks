# Zola

Zola 0.23.6 on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/content/posts` (TOML `+++` front matter), then times `zola build`; each post must render to `public/posts/*/index.html` (the verification step checks the count equals the requested number of files). The index (`templates/index.html`) is a single page listing every post; post pages render only their own title and content. Run it with `./ssgberk --test zola -nf 10` from the toolset repository.

Output after the build: `public/` holds `index.html`, `posts/<slug>/index.html` per post, and empty `404.html`, `robots.txt`, `sitemap.xml` (empty template overrides in `src/templates`, so Zola does no extra work for them). The posts section has `render = false`, so there is no `public/posts/index.html`.
