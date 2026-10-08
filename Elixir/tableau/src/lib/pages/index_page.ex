defmodule SSGBerk.IndexPage do
  use Tableau.Page,
    layout: SSGBerk.RootLayout,
    permalink: "/",
    title: "SSGBerk Reference"

  def template(assigns) do
    items =
      assigns.site.pages
      |> Enum.filter(& &1[:__tableau_post_extension__])
      |> Enum.sort_by(& &1.date, {:desc, DateTime})
      |> Enum.map_join("\n", fn post ->
        """
        <li class="post-item">
        <h2 class="post-item-title"><a href="#{post.permalink}/">#{post.title}</a></h2>
        <time class="post-item-date" datetime="#{DateTime.to_iso8601(post.date)}">#{Date.to_iso8601(DateTime.to_date(post.date))}</time>
        <p class="post-item-summary">#{post.summary}</p>
        </li>\
        """
      end)

    """
    <section class="posts" id="posts">
    <h1 class="page-title">Posts</h1>
    <ol class="post-list">
    #{items}
    </ol>
    </section>
    """
  end
end
