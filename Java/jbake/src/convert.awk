# Converts the benchmark's YAML front matter (--- ... ---) into JBake's header
# (key=value lines, then ~~~~~~). One awk process handles all files given.
FNR == 1 {
    if (out != "") close(out)
    n = split(FILENAME, parts, "/")
    out = "content/posts/" parts[n]
    state = 0; tags = ""; hdr = ""
}
state == 0 && $0 == "---" { state = 1; next }
state == 1 {
    if ($0 == "---") {
        printf "%s", hdr > out
        if (tags != "") printf "tags=%s\n", tags > out
        printf "~~~~~~\n" > out
        state = 2
        next
    }
    if ($0 ~ /^ +- /) { v = $0; sub(/^ +- /, "", v); tags = (tags == "" ? v : tags "," v); next }
    p = index($0, ": ")
    if (p > 0 && $0 != "tags:") hdr = hdr substr($0, 1, p - 1) "=" substr($0, p + 2) "\n"
    next
}
state == 2 { print > out }
END { if (out != "") close(out) }
