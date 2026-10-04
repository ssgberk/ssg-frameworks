import { slugs, post } from '../../../lib/posts';

export const dynamicParams = false;
export function generateStaticParams() { return slugs().map((slug) => ({ slug })); }

export default async function Post({ params }) {
  const { slug } = await params;
  const p = post(slug);
  return (<article><h1>{p.title}</h1><div dangerouslySetInnerHTML={{ __html: p.html }} /></article>);
}
