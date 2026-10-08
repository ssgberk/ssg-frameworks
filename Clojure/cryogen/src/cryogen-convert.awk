# One pass over every generated post (file names arrive on stdin, one per line):
# turns the YAML front matter into Cryogen's leading EDN metadata map and copies the body.
# Runs once per build for all posts; there is no per-post process.
{
    f = $0
    n = split(f, parts, "/")
    o = "content/md/posts/" parts[n]
    st = 0; tags = ""; taglist = ""
    while ((getline line < f) > 0) {
        if (st == 0) { st = 1; continue }
        if (st == 1) {
            if (line == "---") {
                printf "{:layout :post\n :title \"%s\"\n :date \"%s\"\n :summary \"%s\"\n :author \"%s\"\n :tags [%s]\n :tag-order [%s]}\n\n", title, date, summary, author, tags, tags > o
                st = 2
            } else if (line ~ /^title: /) title = substr(line, 8)
            else if (line ~ /^date: /) date = substr(line, 7)
            else if (line ~ /^summary: /) summary = substr(line, 10)
            else if (line ~ /^author: /) author = substr(line, 9)
            else if (line ~ /^    - /) tags = tags (tags == "" ? "" : " ") "\"" substr(line, 7) "\""
            continue
        }
        print line > o
    }
    close(f); close(o)
}
