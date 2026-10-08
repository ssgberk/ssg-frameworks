# Plenti reads content/<type>/*.json, not markdown. build.sh writes "---<yaml>---<markdown>"
# posts; this single awk pass (one process for all posts) turns each one into a JSON file with
# title, date, summary, author, tags and the raw markdown body. The body is rendered to HTML on
# the Plenti/Svelte side (layouts/content/post.svelte).
function esc(s) {
    gsub(/\\/, "\\\\\\\\", s)
    gsub(/"/, "\\\\\"", s)
    return s
}
# Plenti collapses every whitespace run in the content to one space before it reaches the
# layouts, which would flatten nested markdown lists. Runs of 2+ spaces are therefore written
# as JSON \u0020 escapes, which survive the collapse and decode back to spaces.
function keep(s,   r) {
    r = ""
    while (match(s, /  +/)) {
        r = r substr(s, 1, RSTART - 1)
        for (q = 0; q < RLENGTH; q++) r = r "\\u0020"
        s = substr(s, RSTART + RLENGTH)
    }
    return r s
}
function finish() {
    if (cur != "") { printf "\"}\n" > cur; close(cur) }
}
FNR == 1 {
    finish()
    n = split(FILENAME, p, "/")
    name = p[n]
    sub(/\.md$/, "", name)
    cur = "content/post/" name ".json"
    state = 1
    tags = ""
    next
}
state == 1 {
    if ($0 == "---") {
        printf "{\"title\":\"%s\",\"date\":\"%s\",\"summary\":\"%s\",\"author\":\"%s\",\"tags\":[%s],\"body\":\"", title, date, summary, author, tags > cur
        state = 2
    } else if (substr($0, 1, 7) == "title: ") title = esc(substr($0, 8))
    else if (substr($0, 1, 6) == "date: ") date = esc(substr($0, 7))
    else if (substr($0, 1, 9) == "summary: ") summary = esc(substr($0, 10))
    else if (substr($0, 1, 8) == "author: ") author = esc(substr($0, 9))
    else if (substr($0, 1, 6) == "    - ") tags = tags (tags == "" ? "" : ",") "\"" esc(substr($0, 7)) "\""
    next
}
{ line = esc($0); if (index(line, "  ")) line = keep(line); printf "%s\\n", line > cur }
END { finish() }
