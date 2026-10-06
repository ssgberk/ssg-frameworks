// Blog-only Docusaurus site: posts at /posts/YYYY/MM/DD/<slug>/, one index page, no navbar/footer.
/** @type {import('@docusaurus/types').Config} */
module.exports = {
  title: 'SSGBerk Docusaurus',
  url: 'https://example.com',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  plugins: [
    // Hands every blog post (title + permalink) to the index page as global data.
    function postListPlugin() {
      return {
        name: 'ssgberk-post-list',
        async allContentLoaded({ allContent, actions }) {
          const blog = allContent['docusaurus-plugin-content-blog'];
          const posts = Object.values(blog || {})[0]?.blogPosts || [];
          actions.setGlobalData(
            posts
              .map((p) => ({ title: p.metadata.title, permalink: p.metadata.permalink }))
              .sort((a, b) => a.permalink.localeCompare(b.permalink)),
          );
        },
      };
    },
  ],
  presets: [
    [
      'classic',
      {
        docs: false,
        blog: {
          path: 'blog',
          routeBasePath: 'posts',
          postsPerPage: 'ALL',
          blogSidebarCount: 0,
          showReadingTime: false,
          feedOptions: { type: null },
          archiveBasePath: null,
          onInlineTags: 'ignore',
          onInlineAuthors: 'ignore',
          onUntruncatedBlogPosts: 'ignore',
        },
        pages: { path: 'src/pages' },
        theme: {},
        sitemap: false,
        gtag: undefined,
      },
    ],
  ],
};
