export async function onBeforePrerenderStart() {
  const files = import.meta.glob('/src/posts/*.md', { query: '?url' });
  return Object.keys(files).map((path) => `/posts/${path.split('/').pop().replace(/\.md$/, '')}/`);
}
