defmodule SSGBerk.RootLayout do
  use Tableau.Layout

  def template(assigns) do
    title =
      if assigns.page[:__tableau_post_extension__],
        do: assigns.page.title <> " | SSGBerk Reference",
        else: assigns.page.title

    home_current = if assigns.page[:permalink] == "/", do: ~s( aria-current="page"), else: ""

    """
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#{title}</title>
    <link rel="stylesheet" href="/assets/ssgberk.css">
    </head>
    <body>
    <header class="site-header">
    <a class="site-title" href="/">SSGBerk Reference</a>
    <nav class="site-nav">
    <ul>
    <li><a href="/"#{home_current}>Home</a></li>
    <li><a href="/#posts">Posts</a></li>
    <li><a href="https://github.com/ssgberk">Source</a></li>
    </ul>
    </nav>
    </header>
    <main class="site-main">
    #{render(assigns.inner_content)}
    </main>
    <footer class="site-footer">
    <p>Built for the SSGBerk build-time benchmark.</p>
    </footer>
    </body>
    </html>
    """
  end
end
