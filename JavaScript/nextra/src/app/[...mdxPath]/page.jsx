import { generateStaticParamsFor, importPage } from 'nextra/pages';
import { useMDXComponents } from '../../mdx-components';

export const generateStaticParams = generateStaticParamsFor('mdxPath');
export const dynamicParams = false;

const Wrapper = useMDXComponents().wrapper;

export default async function Page(props) {
  const params = await props.params;
  const { default: MDXContent, metadata } = await importPage(params.mdxPath);
  return (<Wrapper metadata={metadata}><MDXContent {...props} params={params} /></Wrapper>);
}
