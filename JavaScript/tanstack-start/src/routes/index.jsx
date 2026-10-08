import { createFileRoute, Link } from '@tanstack/react-router';
import { listPosts } from '../posts';

export const Route = createFileRoute('/')({
  loader: () => listPosts(),
  head: () => ({ meta: [{ title: 'Posts' }] }),
  component: Index,
});

function Index() {
  const posts = Route.useLoaderData();
  return (
    <>
      <h1>Posts</h1>
      <ul>
        {posts.map((p) => (
          <li key={p.slug}>
            <Link to="/posts/$slug" params={{ slug: p.slug }}>{p.title}</Link>
          </li>
        ))}
      </ul>
    </>
  );
}
