import fs from 'node:fs';
import path from 'node:path';
import matter from 'gray-matter';
import { marked } from 'marked';

const dir = path.join(process.cwd(), 'content/posts');

export function slugs() {
  return fs.readdirSync(dir).filter((f) => f.endsWith('.md')).map((f) => f.slice(0, -3));
}

export function post(slug) {
  const { data, content } = matter(fs.readFileSync(path.join(dir, `${slug}.md`), 'utf8'));
  return { title: data.title, html: marked.parse(content) };
}
