# Posts carry no front matter (Franklin evaluates `+++` blocks as Julia, not TOML),
# so title and date come from the file name YYYY-MM-DD-NNN.md.
function post_parts(rp)
    stem = splitext(basename(rp))[1]
    return stem[1:10], stem[12:end]
end

function hfun_pagetitle()
    rp = locvar("fd_rpath")::String
    startswith(rp, "posts/") && return "Post " * post_parts(rp)[2] * " | SSGBerk Reference"
    rp == "404.md" && return "Page not found | SSGBerk Reference"
    return "SSGBerk Reference"
end

function hfun_postmeta()
    day, n = post_parts(locvar("fd_rpath")::String)
    return "<h1 class=\"post-title\">Post $n</h1>\n<p class=\"post-meta\"><time class=\"post-date\" datetime=\"$day\">$day</time></p>"
end

function hfun_postlist()
    io = IOBuffer()
    println(io, "<section class=\"posts\" id=\"posts\">\n<h1 class=\"page-title\">Posts</h1>\n<ol class=\"post-list\">")
    for f in sort(filter(endswith(".md"), readdir("posts")))
        day, n = post_parts(f)
        println(io, "<li class=\"post-item\">\n<h2 class=\"post-item-title\"><a href=\"/posts/$day-$n/\">Post $n</a></h2>\n<time class=\"post-item-date\" datetime=\"$day\">$day</time>\n</li>")
    end
    println(io, "</ol>\n</section>")
    return String(take!(io))
end
