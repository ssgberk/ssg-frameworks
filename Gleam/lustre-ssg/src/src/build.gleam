//// SSGBerk reference site: reads content/posts/*.md at build time, renders every
//// post with mork (CommonMark + GFM tables) and lays pages out with Lustre elements.
//// lustre_ssg writes public/index.html, public/404.html and public/posts/<slug>.html.

import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import lustre/attribute.{attribute, class, href}
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/ssg
import mork
import simplifile

const posts_dir = "content/posts"

type Post {
  Post(
    slug: String,
    title: String,
    datetime: String,
    summary: String,
    author: String,
    tags: List(String),
    body: String,
  )
}

pub fn main() -> Nil {
  let posts = load_posts()
  let by_slug = list.map(posts, fn(p) { #(p.slug, p) }) |> dict.from_list

  let result =
    ssg.new("./public")
    |> ssg.add_static_dir("./static")
    |> ssg.add_static_route("/", index_page(posts))
    |> ssg.add_static_route("/404", not_found_page())
    |> ssg.add_dynamic_route("/posts", by_slug, post_page)
    |> ssg.build

  case result {
    Ok(_) -> io.println("Built " <> string.inspect(list.length(posts)) <> " posts")
    Error(e) -> {
      io.println_error("Build failed: " <> string.inspect(e))
      halt(1)
    }
  }
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> Nil

// CONTENT ---------------------------------------------------------------------

fn load_posts() -> List(Post) {
  let assert Ok(names) = simplifile.read_directory(posts_dir)
  names
  |> list.filter(string.ends_with(_, ".md"))
  |> list.map(fn(name) {
    let assert Ok(source) = simplifile.read(posts_dir <> "/" <> name)
    parse_post(string.drop_end(name, 3), source)
  })
  |> list.sort(fn(a, b) { string.compare(b.datetime, a.datetime) })
}

fn parse_post(slug: String, source: String) -> Post {
  let #(front, body) = mork.split_frontmatter_from_input(source)
  let meta = parse_front_matter(front)
  let html =
    mork.configure()
    |> mork.tables(True)
    |> mork.parse_with_options(body)
    |> mork.to_html
  Post(
    slug: slug,
    title: field(meta.0, "title"),
    datetime: field(meta.0, "date"),
    summary: field(meta.0, "summary"),
    author: field(meta.0, "author"),
    tags: meta.1,
    body: html,
  )
}

/// Minimal YAML front matter reader for the benchmark schema: `key: value`
/// scalars plus one block list (`tags:` followed by `- item` lines).
fn parse_front_matter(front: String) -> #(List(#(String, String)), List(String)) {
  let #(pairs, tags) =
    string.split(front, "\n")
    |> list.fold(#([], []), fn(acc, line) {
      let trimmed = string.trim(line)
      case string.starts_with(trimmed, "- ") {
        True -> #(acc.0, [string.drop_start(trimmed, 2), ..acc.1])
        False ->
          case string.split_once(trimmed, ": ") {
            Ok(#(key, value)) -> #([#(key, value), ..acc.0], acc.1)
            Error(_) -> acc
          }
      }
    })
  #(pairs, list.reverse(tags))
}

fn field(pairs: List(#(String, String)), key: String) -> String {
  case list.key_find(pairs, key) {
    Ok(value) -> value
    Error(_) -> ""
  }
}

fn day(datetime: String) -> String {
  string.slice(datetime, 0, 10)
}

// VIEWS -----------------------------------------------------------------------

fn layout(
  page_title: String,
  current_home: Bool,
  content: List(Element(Nil)),
) -> Element(Nil) {
  let home_attrs = case current_home {
    True -> [href("/"), attribute("aria-current", "page")]
    False -> [href("/")]
  }
  html.html([attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute("charset", "utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.title([], page_title),
      html.link([
        attribute.rel("stylesheet"),
        href("/assets/ssgberk.css"),
      ]),
    ]),
    html.body([], [
      html.header([class("site-header")], [
        html.a([class("site-title"), href("/")], [text("SSGBerk Reference")]),
        html.nav([class("site-nav")], [
          html.ul([], [
            html.li([], [html.a(home_attrs, [text("Home")])]),
            html.li([], [html.a([href("/#posts")], [text("Posts")])]),
            html.li([], [
              html.a([href("https://github.com/ssgberk")], [text("Source")]),
            ]),
          ]),
        ]),
      ]),
      html.main([class("site-main")], content),
      html.footer([class("site-footer")], [
        html.p([], [text("Built for the SSGBerk build-time benchmark.")]),
      ]),
    ]),
  ])
}

fn index_page(posts: List(Post)) -> Element(Nil) {
  layout("SSGBerk Reference", True, [
    html.section([class("posts"), attribute.id("posts")], [
      html.h1([class("page-title")], [text("Posts")]),
      html.ol(
        [class("post-list")],
        list.map(posts, fn(p) {
          html.li([class("post-item")], [
            html.h2([class("post-item-title")], [
              html.a([href("/posts/" <> p.slug <> ".html")], [text(p.title)]),
            ]),
            html.time(
              [class("post-item-date"), attribute("datetime", p.datetime)],
              [text(day(p.datetime))],
            ),
            html.p([class("post-item-summary")], [text(p.summary)]),
          ])
        }),
      ),
    ]),
  ])
}

fn post_page(p: Post) -> Element(Nil) {
  layout(p.title <> " | SSGBerk Reference", False, [
    html.article([class("post")], [
      html.h1([class("post-title")], [text(p.title)]),
      html.p([class("post-meta")], [
        html.time([class("post-date"), attribute("datetime", p.datetime)], [
          text(day(p.datetime)),
        ]),
        text(" by "),
        html.span([class("post-author")], [text(p.author)]),
      ]),
      html.ul(
        [class("post-tags")],
        list.map(p.tags, fn(t) { html.li([class("post-tag")], [text(t)]) }),
      ),
      element.unsafe_raw_html("", "div", [class("post-body")], p.body),
    ]),
  ])
}

fn not_found_page() -> Element(Nil) {
  layout("Page not found | SSGBerk Reference", False, [
    html.section([class("not-found")], [
      html.h1([class("page-title")], [text("Page not found")]),
      html.p([], [html.a([href("/")], [text("Back to the posts")])]),
    ]),
  ])
}
