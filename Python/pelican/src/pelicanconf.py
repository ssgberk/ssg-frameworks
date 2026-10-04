AUTHOR = "SSGBerk"
SITENAME = "SSGBerk Pelican"
SITEURL = ""
PATH = "content"
OUTPUT_PATH = "output"
TIMEZONE = "UTC"
DEFAULT_LANG = "en"
THEME = "theme"

ARTICLE_URL = "posts/{slug}/"
ARTICLE_SAVE_AS = "posts/{slug}/index.html"

# Only the single index page may list posts: disable every other listing.
DIRECT_TEMPLATES = ["index"]
ARCHIVES_SAVE_AS = ""
CATEGORIES_SAVE_AS = ""
CATEGORY_SAVE_AS = ""
TAGS_SAVE_AS = ""
TAG_SAVE_AS = ""
AUTHORS_SAVE_AS = ""
AUTHOR_SAVE_AS = ""
DEFAULT_PAGINATION = False

FEED_ALL_ATOM = None
FEED_ALL_RSS = None
CATEGORY_FEED_ATOM = None
CATEGORY_FEED_RSS = None
TRANSLATION_FEED_ATOM = None
TRANSLATION_FEED_RSS = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

MARKDOWN = {"extension_configs": {"markdown.extensions.meta": {}}}
