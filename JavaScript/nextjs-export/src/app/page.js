import { slugs } from '../lib/posts';

export default function Home() {
  return (
    <ul>
      {slugs().map((s) => (
        <li key={s}><a href={`/posts/${s}/`}>{s}</a></li>
      ))}
    </ul>
  );
}
