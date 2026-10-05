import fs from 'node:fs';
import path from 'node:path';

export default function Home() {
  const dir = path.join(process.cwd(), 'content/posts');
  const slugs = fs.readdirSync(dir).filter((f) => f.endsWith('.md')).map((f) => f.slice(0, -3));
  return (
    <ul>
      {slugs.map((s) => (
        <li key={s}><a href={`/posts/${s}/`}>{s}</a></li>
      ))}
    </ul>
  );
}
