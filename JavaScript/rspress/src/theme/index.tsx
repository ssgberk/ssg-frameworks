import { Content, usePage, usePages } from '@rspress/core/runtime';
import React from 'react';

function Layout() {
  const { page } = usePage();
  if (page.routePath === '/') {
    const { pages } = usePages();
    const posts = pages
      .filter((p) => p.routePath.startsWith('/posts/'))
      .sort((a, b) => a.routePath.localeCompare(b.routePath));
    return (
      <main>
        <h1>SSGBerk Rspress</h1>
        <ul>
          {posts.map((p) => (
            <li key={p.routePath}>
              <a href={`${p.routePath}.html`}>{p.title}</a>
            </li>
          ))}
        </ul>
      </main>
    );
  }
  return (
    <main>
      <h1>{page.title}</h1>
      <Content />
    </main>
  );
}

export { Layout };
export * from '@rspress/core/theme-original';
