import { useMDXComponents as getNextraComponents } from 'nextra/mdx-components';

const components = getNextraComponents({
  wrapper({ children, metadata }) {
    return (<article><h1>{metadata.title}</h1>{children}</article>);
  },
});

export const useMDXComponents = (extra) => ({ ...components, ...extra });
