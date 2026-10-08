import Config

config :tableau, :config,
  url: "http://localhost",
  out_dir: "_site",
  include_dir: "extra"

config :tableau, Tableau.PostExtension,
  enabled: true,
  dir: "_posts",
  permalink: "/posts/:title",
  layout: SSGBerk.PostLayout

config :tableau, Tableau.PageExtension, enabled: false
config :tableau, Tableau.SitemapExtension, enabled: false
config :tableau, Tableau.RSSExtension, enabled: false
config :tableau, Tableau.TagExtension, enabled: false
config :tableau, Tableau.DataExtension, enabled: false

config :elixir, :time_zone_database, Tz.TimeZoneDatabase
