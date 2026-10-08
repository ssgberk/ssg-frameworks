import { createFileRoute } from '@tanstack/react-router';
import { getPost } from '../../../posts';

export const Route = createFileRoute('/posts/$slug/')({
  loader: ({ params }) => getPost({ data: params.slug }),
  head: ({ loaderData }) => ({ meta: [{ title: loaderData?.title }] }),
  component: Post,
});

function Post() {
  const post = Route.useLoaderData();
  return (
    <>
      <h1>{post.title}</h1>
      <div dangerouslySetInnerHTML={{ __html: post.html }} />
    </>
  );
}
