# Antora

Antora 3.2.1 (`@antora/cli`, `@antora/site-generator`) on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. `build.sh` generates the posts (content type `none`, markdown, no front matter) into `src/modules/ROOT/pages/posts`, then times `npx antora --quiet antora-playbook.yml`; each post must render to `build/site/posts/*.html` (`index.html` and the assets sit outside that glob).

## How it fits

Antora only reads AsciiDoc, from git content sources. The image makes `/opt/antora/src` a one-commit git repository, and the playbook reads it with `url: .`, `branches: HEAD`, `worktrees: .`, so the untracked posts that `build.sh` writes are read from the working tree. The timed build is offline (verified with `docker run --network none`).

- **Markdown to AsciiDoc:** `ssgberk-md-adapter.js` is an Antora extension (`contentAggregated` event). In the same Antora process, with no extra forks, it converts every `pages/**/*.md` file to an in-memory `.adoc` page and adds an `index.adoc` that lists all posts. The converter is a small line-based translator that covers exactly the constructs of the spec 005 content (headings, emphasis, strong, code spans, links, nested bullet and ordered lists, blockquote, fenced code, pipe table, block image, horizontal rule). Anything else markdown allows is passed through as AsciiDoc text and is not converted. This conversion is part of the timed build.
- **UI bundle:** a minimal local bundle (`src/ui`: one `default.hbs` layout and `css/ssgberk.css`), zipped to `ui-bundle.zip` at image build. Antora never fetches a bundle.
- **Assets:** `ssgberk.css` is published at `_/css/ssgberk.css` (UI bundle) and `ssgberk.png` at `_images/ssgberk.png` (`modules/ROOT/images`), referenced with Antora's `image::` macro. They are byte-identical copies of `reference/assets`, but not served under `/assets/`, which Antora does not support.
- **Page layout:** post pages render only the title and the post body; no navbar, sidebar, TOC or search. Post and index pages are `build/site/posts/<date>-<NNN>.html` and `build/site/index.html`; post titles come from the file name (`Post NNN`) because the content type has no front matter.
- **Caches:** `.cache/antora` (`runtime.cache_dir`) is listed in `cache_folders`.

Version is read from `package.json`/`package-lock.json` (`versionFrom` npm `@antora/cli`). Run it with `./ssgberk --test antora -nf 10` from the toolset repository.
