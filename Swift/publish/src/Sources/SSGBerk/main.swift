import Foundation
import Ink
import Plot
import Publish

struct Reference: Website {
    enum SectionID: String, WebsiteSectionID {
        case posts
    }

    struct ItemMetadata: WebsiteItemMetadata {
        var summary: String?
        var author: String?
    }

    var url = URL(string: "https://example.com")!
    var name = "SSGBerk Reference"
    var description = "SSGBerk reference site"
    var language: Language { .english }
    var imagePath: Path? { nil }
}

private let isoDay: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "UTC")
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

private let isoFull: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "UTC")
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    return f
}()

private func page(title: String, current: Bool, _ content: Node<HTML.BodyContext>...) -> HTML {
    HTML(
        .lang(.english),
        .head(
            .encoding(.utf8),
            .viewport(.accordingToDevice),
            .title(title),
            .stylesheet("/assets/ssgberk.css")
        ),
        .body(
            .header(
                .class("site-header"),
                .a(.class("site-title"), .href("/"), .text("SSGBerk Reference")),
                .nav(
                    .class("site-nav"),
                    .ul(
                        .li(.a(.href("/"), .if(current, .attribute(named: "aria-current", value: "page")), .text("Home"))),
                        .li(.a(.href("/#posts"), .text("Posts"))),
                        .li(.a(.href("https://github.com/ssgberk"), .text("Source")))
                    )
                )
            ),
            .main(.class("site-main"), .group(content)),
            .footer(.class("site-footer"), .p(.text("Built for the SSGBerk build-time benchmark.")))
        )
    )
}

private func postList(_ context: PublishingContext<Reference>) -> HTML {
    page(
        title: "SSGBerk Reference",
        current: true,
        .section(
            .class("posts"), .id("posts"),
            .h1(.class("page-title"), .text("Posts")),
            .ol(
                .class("post-list"),
                .forEach(context.allItems(sortedBy: \.date, order: .descending)) { item in
                    .li(
                        .class("post-item"),
                        .h2(.class("post-item-title"), .a(.href(item.path), .text(item.title))),
                        .element(named: "time", nodes: [
                            .class("post-item-date"),
                            .attribute(named: "datetime", value: isoFull.string(from: item.date)),
                            .text(isoDay.string(from: item.date))
                        ]),
                        .p(.class("post-item-summary"), .text(item.metadata.summary ?? ""))
                    )
                }
            )
        )
    )
}

struct ReferenceHTMLFactory: HTMLFactory {
    func makeIndexHTML(for index: Index, context: PublishingContext<Reference>) throws -> HTML {
        postList(context)
    }

    func makeSectionHTML(for section: Section<Reference>, context: PublishingContext<Reference>) throws -> HTML {
        postList(context)
    }

    func makeItemHTML(for item: Item<Reference>, context: PublishingContext<Reference>) throws -> HTML {
        page(
            title: "\(item.title) | SSGBerk Reference",
            current: false,
            .article(
                .class("post"),
                .h1(.class("post-title"), .text(item.title)),
                .p(
                    .class("post-meta"),
                    .element(named: "time", nodes: [
                        .class("post-date"),
                        .attribute(named: "datetime", value: isoFull.string(from: item.date)),
                        .text(isoDay.string(from: item.date))
                    ]),
                    .text(" by "),
                    .span(.class("post-author"), .text(item.metadata.author ?? ""))
                ),
                .ul(
                    .class("post-tags"),
                    .forEach(item.tags) { tag in .li(.class("post-tag"), .text(tag.string)) }
                ),
                .div(.class("post-body"), .raw(item.body.html))
            )
        )
    }

    func makePageHTML(for page: Page, context: PublishingContext<Reference>) throws -> HTML {
        postList(context)
    }

    func makeTagListHTML(for page: TagListPage, context: PublishingContext<Reference>) throws -> HTML? { nil }

    func makeTagDetailsHTML(for page: TagDetailsPage, context: PublishingContext<Reference>) throws -> HTML? { nil }
}

extension PublishingStep where Site == Reference {
    /// Ink's metadata block cannot read the YAML list used for `tags:` in the shared 3minus
    /// front matter, so this step parses it and builds the items itself.
    static func addPosts() -> Self {
        .step(named: "Add posts") { context in
            let parser = MarkdownParser()
            let dateParser = DateFormatter()
            dateParser.locale = Locale(identifier: "en_US_POSIX")
            dateParser.timeZone = TimeZone(identifier: "UTC")
            dateParser.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            for file in try context.folder(at: "Content/posts").files where file.extension == "md" {
                let lines = try file.readAsString().components(separatedBy: "\n")
                var fields = [String: String]()
                var tags = [String]()
                var bodyStart = 0
                if lines.first == "---", let end = lines.dropFirst().firstIndex(of: "---") {
                    for line in lines[1..<end] {
                        if line.hasPrefix(" ") || line.hasPrefix("-") {
                            tags.append(line.trimmingCharacters(in: .whitespaces).dropFirst(2).description)
                        } else if let colon = line.firstIndex(of: ":") {
                            fields[String(line[..<colon])] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                        }
                    }
                    bodyStart = end + 1
                }
                let html = parser.html(from: lines[bodyStart...].joined(separator: "\n"))
                context.addItem(Item(
                    path: Path(file.nameExcludingExtension),
                    sectionID: .posts,
                    metadata: Reference.ItemMetadata(summary: fields["summary"], author: fields["author"]),
                    tags: tags.map(Tag.init),
                    content: Content(
                        title: fields["title"] ?? file.nameExcludingExtension,
                        description: fields["summary"] ?? "",
                        body: Content.Body(html: html),
                        date: dateParser.date(from: fields["date"] ?? "") ?? Date(timeIntervalSince1970: 0)
                    )
                ))
            }
        }
    }
}

try Reference().publish(using: [
    .addPosts(),
    .copyResources(),
    .generateHTML(withTheme: Theme(htmlFactory: ReferenceHTMLFactory()))
])
