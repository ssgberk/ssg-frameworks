defmodule SSGBerk.NotFoundPage do
  use Tableau.Page,
    layout: SSGBerk.RootLayout,
    permalink: "/404.html",
    title: "Page not found | SSGBerk Reference"

  def template(_assigns) do
    """
    <section class="not-found">
    <h1 class="page-title">Page not found</h1>
    <p><a href="/">Back to the posts</a></p>
    </section>
    """
  end
end
