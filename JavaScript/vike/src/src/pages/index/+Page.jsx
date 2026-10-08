import { useData } from 'vike-react/useData';

export default function Page() {
  const { posts } = useData();
  return (
    <>
      <h1>Posts</h1>
      <ul>
        {posts.map((p) => (
          <li key={p.slug}>
            <a href={`/posts/${p.slug}/`}>{p.title}</a>
          </li>
        ))}
      </ul>
    </>
  );
}
