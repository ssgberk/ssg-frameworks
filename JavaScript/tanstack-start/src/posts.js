import { createServerFn } from '@tanstack/react-start';
import fm from 'front-matter';
import { marked } from 'marked';

const files = () => import.meta.glob('/src/posts/*.md', { eager: true, query: '?raw', import: 'default' });

const slugOf = (path) => path.slice(path.lastIndexOf('/') + 1, -3);

export const listPosts = createServerFn({ method: 'GET' }).handler(() =>
  Object.entries(files())
    .map(([path, raw]) => ({ slug: slugOf(path), title: fm(raw).attributes.title }))
    .sort((a, b) => a.slug.localeCompare(b.slug)),
);

export const getPost = createServerFn({ method: 'GET' })
  .inputValidator((slug) => slug)
  .handler(({ data: slug }) => {
    const raw = files()[`/src/posts/${slug}.md`];
    if (raw === undefined) throw new Error('Not found');
    const { attributes, body } = fm(raw);
    return { title: attributes.title, html: marked.parse(body) };
  });
