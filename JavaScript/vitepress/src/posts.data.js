import { createContentLoader } from 'vitepress';

export default createContentLoader('posts/*.md', {
  transform: (raw) =>
    raw
      .map(({ url, frontmatter }) => ({ url, title: frontmatter.title }))
      .sort((a, b) => a.url.localeCompare(b.url)),
});
