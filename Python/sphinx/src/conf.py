project = "SSGBerk Sphinx"
extensions = ["myst_parser"]
source_suffix = {".md": "markdown"}
master_doc = "index"
exclude_patterns = ["_build", "_theme", "assets/*.css"]
suppress_warnings = ["myst.header", "myst.xref_missing"]

html_theme = "minimal"
html_theme_path = ["_theme"]
html_copy_source = False
html_show_sourcelink = False
html_use_index = False
html_domain_indices = False
html_use_opensearch = ""
html_permalinks = False
html_title = project


def add_title(app, docname, source):
    # MyST keeps the front-matter title as metadata only; prepend it as the H1 so
    # every post has one document title (otherwise each "## Chapter" is a top-level section).
    text = source[0]
    if docname.startswith("posts/") and text.startswith("---\n"):
        end = text.find("\n---\n", 4) + 5
        for line in text[4:end].split("\n"):
            if line.startswith("title: "):
                source[0] = text[:end] + "\n# " + line[7:] + "\n\n" + text[end:]
                break


def setup(app):
    # No search page, search index or opensearch description.
    app.connect("builder-inited", lambda app: setattr(app.builder, "search", False))
    app.connect("source-read", add_title)
