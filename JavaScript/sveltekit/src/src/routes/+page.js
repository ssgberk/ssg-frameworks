export function load() {
  const posts = import.meta.glob('/src/posts/*.md', { eager: true, import: 'metadata' });
  return {
    posts: Object.entries(posts)
      .map(([path, meta]) => ({ slug: path.split('/').pop().replace(/\.md$/, ''), title: meta.title }))
      .sort((a, b) => a.slug.localeCompare(b.slug)),
  };
}
