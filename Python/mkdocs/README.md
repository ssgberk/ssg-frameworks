# MkDocs

MkDocs 1.6.1 (Jinja2 templates, minimal custom theme in `src/theme`) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/docs/posts` (plain Markdown, no front matter; the title is derived from the file name), then times `mkdocs build -q`; each post must render to `site/posts/*/index.html` (the verification step checks the count equals the requested number of files). MkDocs writes no cache besides `site/`, so `cache_folders` is empty. Run it with `./ssgberk --test mkdocs -nf 10` from the toolset repository.

`requirements.txt` is the full `pip freeze` of `pip install mkdocs==1.6.1` taken inside the built image, so every transitive dependency is pinned. No plugins are used (`plugins: []`, which also disables search) and no theme assets are produced. The custom theme's `main.html` renders only the title and content on post pages; on the homepage (`docs/index.md`) it lists every page under `posts/` from `nav.pages`, so there is a single index listing all posts.

Titles on the index come from the file names (content type `none`: the generated Markdown has no front matter), not from a title field.

Output after the build: `site/` holds only `index.html` and `posts/<name>/index.html` per post. An empty `src/theme/sitemap.xml` makes MkDocs skip the sitemap, so no `sitemap.xml` or `sitemap.xml.gz` is produced.
