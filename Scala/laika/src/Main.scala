//> using scala 3.3.8
//> using dep org.typelevel::laika-io:1.3.2
//> using options -deprecation

import cats.effect.{ExitCode, IO, IOApp}
import laika.api.Transformer
import laika.api.bundle.{ConfigHeaderParser, ConfigProvider, DirectiveRegistry, ExtensionBundle, ParserBundle, TemplateDirectives}
import laika.api.config.ConfigParser
import laika.ast.TemplateString
import laika.format.{HTML, Markdown}
import laika.io.syntax.*
import laika.config.SyntaxHighlighting

import laika.io.model.FilePath
import laika.parse.Parser
import laika.parse.text.TextParsers.{delimitedBy, literal}
import laika.theme.Theme

/** `@:postList` renders the index: one list item per post, newest first (date strings sort lexicographically). */
object PostList extends DirectiveRegistry:
  val spanDirectives  = Seq()
  val blockDirectives = Seq()
  val linkDirectives  = Seq()
  val templateDirectives = Seq(
    TemplateDirectives.create("postList") {
      TemplateDirectives.dsl.cursor.map { cursor =>
        val posts = cursor.root.target.tree.allDocuments
          .filter(_.path.parent.name == "posts")
          .map(d => (d, d.config.get[String]("date").getOrElse("")))
          .sortBy(_._2)
          .reverse
        val sb = new StringBuilder("<ol class=\"post-list\">\n")
        posts.foreach { case (d, date) =>
          val title   = d.config.get[String]("title").getOrElse(d.path.name)
          val summary = d.config.get[String]("summary").getOrElse("")
          val url     = "/posts/" + d.path.basename + ".html"
          sb ++= s"""<li class="post-item">
<h2 class="post-item-title"><a href="$url">$title</a></h2>
<time class="post-item-date" datetime="$date">${date.take(10)}</time>
<p class="post-item-summary">$summary</p>
</li>
"""
        }
        sb ++= "</ol>"
        TemplateString(sb.toString)
      }
    }
  )

/** Laika reads HOCON `{% ... %}` headers only. This bundle accepts the YAML `---` front matter the benchmark
  * posts carry: the header is rewritten in memory (flat `key: value` pairs and `- item` lists) into HOCON and
  * handed to Laika's own config parser, so posts are read as they are, with no pre-processing pass.
  */
object YamlFrontMatter extends ExtensionBundle:
  val description = "YAML front matter for Markdown"

  private def quote(v: String) = "\"" + v.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

  def toHocon(yaml: String): String =
    val sb   = new StringBuilder
    var open = false
    yaml.linesIterator.foreach { line =>
      val t = line.trim
      if t.startsWith("- ") then sb ++= quote(t.drop(2).trim) += ','
      else if t.nonEmpty then
        if open then { sb ++= "]\n"; open = false }
        val i = t.indexOf(':')
        val k = t.take(i)
        val v = t.drop(i + 1).trim
        if v.isEmpty then { sb ++= s"$k = ["; open = true }
        else sb ++= s"$k = ${quote(v)}\n"
    }
    if open then sb ++= "]\n"
    sb.toString

  private val header: Parser[String] = (literal("---\n") ~> delimitedBy("\n---")).map(toHocon)

  override val parsers: ParserBundle = ParserBundle(configProvider = Some(new ConfigProvider:
    val markupConfigHeader: Parser[ConfigParser]   = ConfigHeaderParser.forTextParser(header)
    val templateConfigHeader: Parser[ConfigParser] = ConfigHeaderParser.betweenLines("{%", "%}")
    def configDocument(input: String): ConfigParser = ConfigParser.parse(input)
  ))

object Main extends IOApp:
  def run(args: List[String]): IO[ExitCode] = args match
    case List(in, out) =>
      Transformer
        .from(Markdown)
        .to(HTML)
        .using(Markdown.GitHubFlavor, SyntaxHighlighting, YamlFrontMatter, PostList)
        .parallel[IO]
        .withTheme(Theme.empty)
        .build
        .use(_.fromDirectory(FilePath.parse(in)).toDirectory(FilePath.parse(out)).transform)
        .as(ExitCode.Success)
    case _ =>
      IO.consoleForIO.errorln("usage: laika-site <input-dir> <output-dir>").as(ExitCode.Error)
