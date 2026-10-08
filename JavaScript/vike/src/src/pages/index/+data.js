export async function data() {
  const files = import.meta.glob('/src/posts/*.md', { query: '?raw', import: 'default', eager: true });
  const posts = Object.entries(files).map(([path, raw]) => {
    const slug = path.split('/').pop().replace(/\.md$/, '');
    const m = /^title: (.*)$/m.exec(raw);
    return { slug, title: m ? m[1] : slug };
  });
  posts.sort((a, b) => a.slug.localeCompare(b.slug));
  return { posts };
}
