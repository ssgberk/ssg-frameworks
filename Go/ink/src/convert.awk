# Ink reads "<yaml>---<markdown>" and parses dates as "YYYY-MM-DD HH:MM:SS".
# build.sh writes "---<yaml>---<markdown>" with ISO dates, so this single pass drops the
# leading "---" line and rewrites the date value, copying every post into source/post.
FNR == 1 {
    if (cur != "") close(cur)
    n = split(FILENAME, p, "/")
    cur = "source/post/" p[n]
    fm = 1
    next
}
fm && $0 == "---" { fm = 0 }
fm && /^date: / { sub(/T/, " "); sub(/Z$/, "") }
{ print > cur }
