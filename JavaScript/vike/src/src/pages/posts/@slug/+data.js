import { marked } from 'marked';
import { render } from 'vike/abort';

export async function data(pageContext) {
  const files = import.meta.glob('/src/posts/*.md', { query: '?raw', import: 'default', eager: true });
  const raw = files[`/src/posts/${pageContext.routeParams.slug}.md`];
  if (raw === undefined) throw render(404);
  const m = /^---\n([\s\S]*?)\n---\n/.exec(raw);
  const front = m ? m[1] : '';
  const t = /^title: (.*)$/m.exec(front);
  const body = m ? raw.slice(m[0].length) : raw;
  return { title: t ? t[1] : '', html: marked.parse(body) };
}
