import { error } from '@sveltejs/kit';

export async function load({ params }) {
  const posts = import.meta.glob('/src/posts/*.md');
  const loader = posts[`/src/posts/${params.slug}.md`];
  if (!loader) error(404, 'Not found');
  const post = await loader();
  return { content: post.default, title: post.metadata.title };
}
