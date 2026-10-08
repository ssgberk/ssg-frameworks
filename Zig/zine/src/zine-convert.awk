# One awk process for the whole site (no per-post forks): reads post file names from
# stdin and writes content/posts/<name>.smd, i.e. SuperMD with Ziggy front matter.
# Headings move up one level ("##" -> "#"); zine.ziggy sets headings_h2 so they
# still render as <h2>/<h3> (a SuperMD document must start at heading level 1).
{
    n = $0; sub(/^.*\//, "", n); sub(/\.md$/, "", n)
    out = "content/posts/" n ".smd"
    printf "---\n.title = \"%s\",\n.date = .date(\"%sT00:00:00\"),\n.layout = \"post.shtml\",\n---\n", n, substr(n, 1, 10) > out
    while ((getline line < $0) > 0) {
        if (line ~ /^##+ /) line = substr(line, 2)
        else if (line ~ /^~~~/) line = "```"
        print line > out
    }
    close($0); close(out)
}
