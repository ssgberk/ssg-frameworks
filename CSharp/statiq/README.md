# Statiq

Statiq.Web 1.0.0-beta.60 (latest release; Statiq has no stable 1.0 yet) on .NET SDK 10.0.401 (tarball for amd64 and arm64) on Ubuntu 24.04, benchmarked by SSGBerk.

Statiq.Web is a NuGet library, so `app/` holds a small console app (`Bootstrapper.Factory.CreateWeb(args).RunAsync()`). The image restores and builds it into `/opt/statiq/app/bin` (untimed); the timed build runs `dotnet /opt/statiq/app/bin/statiq.dll` from `/opt/statiq/src` with no restore and no network (checked with `docker run --network none`). The package targets netcoreapp3.1, so the app targets net10.0 and the image sets `DOTNET_ROLL_FORWARD=Major`.

`build.sh` generates the posts into `src/input/posts` (content type `3minus`, date key `Published`). `input/_Layout.cshtml` is the Razor layout (reference header, footer, post markup), `input/index.cshtml` lists all posts newest first, `input/404.md` is the not-found page and `input/assets/` holds the reference stylesheet and image. `src/statiq.json` disables the sitemap and keeps `.html` in links. No navigation, search or feeds are configured.

Output is `output/` (`index.html`, `404.html`, `posts/*.html`, `assets/`). Statiq writes `cache/` and `temp/` in the project directory; both are listed in `cache_folders`.
