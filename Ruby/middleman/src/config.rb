activate :blog do |blog|
  blog.sources = "posts/{year}-{month}-{day}-{title}"
  blog.permalink = "posts/{title}/index.html"
  blog.layout = "post"
  blog.paginate = false
  blog.generate_tag_pages = false
  blog.generate_year_pages = false
  blog.generate_month_pages = false
  blog.generate_day_pages = false
end

set :markdown_engine, :kramdown
