import { fileURLToPath } from 'node:url';

const clientConfigFile = fileURLToPath(new URL('./client.js', import.meta.url));

// Minimal theme: one layout that renders only the page content; the home page lists every post.
export default () => ({
  name: 'ssgberk-minimal',
  clientConfigFile,
  onPrepared: async (app) => {
    const posts = app.pages
      .filter((p) => p.path.startsWith('/posts/'))
      .map((p) => ({ path: p.path, title: p.frontmatter.title || p.title }))
      .sort((a, b) => a.path.localeCompare(b.path));
    await app.writeTemp('posts.js', `export default ${JSON.stringify(posts)};\n`);
  },
});
