defmodule SSGBerk.PostLayout do
  use Tableau.Layout, layout: SSGBerk.RootLayout

  def template(assigns) do
    page = assigns.page
    tags = Enum.map_join(page.tags, "\n", fn tag -> ~s(<li class="post-tag">#{tag}</li>) end)

    """
    <article class="post">
    <h1 class="post-title">#{page.title}</h1>
    <p class="post-meta"><time class="post-date" datetime="#{DateTime.to_iso8601(page.date)}">#{Date.to_iso8601(DateTime.to_date(page.date))}</time> by <span class="post-author">#{page.author}</span></p>
    <ul class="post-tags">
    #{tags}
    </ul>
    <div class="post-body">
    #{render(assigns.inner_content)}
    </div>
    </article>
    """
  end
end
