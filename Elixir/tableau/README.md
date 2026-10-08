# Tableau

Tableau 0.30.0 (Erlang/OTP 28.5.0.7, Elixir 1.20.4 from the pinned `hexpm/elixir` Ubuntu 24.04 image) benchmarked by SSGBerk. `build.sh` generates the posts into `src/_posts` (`3minus` front matter), then times `mix tableau.build` with `MIX_ENV=prod`; each post must render to `_site/posts/*/index.html` (the verification step checks the count equals the requested number of files).

Dependencies are pinned by `src/mix.lock`; they are fetched and compiled, together with the site's layout modules, while the image is built, so the timed build needs no network. `Tableau.PostExtension` turns `_posts/*.md` into pages (`/posts/:title`); the layouts (`SSGBerk.RootLayout`, `SSGBerk.PostLayout`) and the index and 404 pages are plain Elixir modules in `src/lib`. Page, sitemap, RSS, tag and data extensions are disabled. Tableau writes no cache outside `_site`. Run it with `./ssgberk --test tableau -nf 10` from the toolset repository.
