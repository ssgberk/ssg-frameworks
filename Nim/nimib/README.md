# nimib

nimib 0.4.2 on Nim 2.2.12 and Ubuntu 24.04, benchmarked by SSGBerk. nimib is a library, so `src/ssgrender.nim` is a small program compiled once when the image is built (untimed). `build.sh` generates the posts into `src/content/post`, then times `./ssgrender`, which reads each post and renders it with nimib (`nbInit`, `nbText`, `nbSave`, default theme) into `public/post/<slug>/index.html`, plus an index page. The timed run does not touch the network (`docker run --network none` works). Run it with `./ssgberk --test nimib -nf 10` from the toolset repository.
