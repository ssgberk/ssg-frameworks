# SSGBerk renderer: a nimib program compiled once at image build time. At run time it
# reads every markdown post in content/post and renders it with nimib (nbText -> markdown ->
# HTML, default nimib theme) into public/post/<slug>/index.html, plus public/index.html.
import std/[os, algorithm, strutils]
import nimib

const contentDir = "content/post"
const outDir = "public"

proc splitFrontMatter(raw: string): tuple[title, body: string] =
  ## Posts start with a "---" delimited YAML block; take the title and drop the block.
  result.body = raw
  if not raw.startsWith("---\n"): return
  let stop = raw.find("\n---\n", 3)
  if stop < 0: return
  for line in raw[4 ..< stop].splitLines:
    if line.startsWith("title: "):
      result.title = line[7 .. ^1]
  result.body = raw[stop + 5 .. ^1]

proc renderPost(slug, title, body: string) =
  nbInit
  nb.doc.filename = outDir / "post" / slug / "index.html"
  nb.title = title
  nbText: "# " & title & "\n\n" & body
  nbSave

var posts: seq[tuple[slug, title: string]]
var files: seq[string]
for f in walkFiles(contentDir / "*.md"):
  files.add f
files.sort()

for f in files:
  let slug = f.splitFile.name
  let (title, body) = splitFrontMatter(readFile(f))
  renderPost(slug, title, body)
  posts.add (slug, title)

block index:
  nbInit
  nb.doc.filename = outDir / "index.html"
  nb.title = "SSGBerk nimib"
  var listing = "# News 'n' Updates\n\n"
  for i in countdown(posts.high, 0):
    listing.add "- [" & posts[i].title & "](post/" & posts[i].slug & "/)\n"
  nbText: listing
  nbSave
