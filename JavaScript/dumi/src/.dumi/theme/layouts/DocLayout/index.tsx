import { Link, Outlet, useLocation, useFullSidebarData } from 'dumi';
import React from 'react';

export default function DocLayout() {
  const { pathname } = useLocation();
  const sidebar = useFullSidebarData();
  if (pathname === '/') {
    const posts: any[] = [];
    Object.values(sidebar || {}).forEach((groups: any) =>
      groups.forEach((g: any) => (g.children || []).forEach((i: any) => posts.push(i))),
    );
    posts.sort((x, y) => x.link.localeCompare(y.link));
    return (
      <main>
        <h1>SSGBerk dumi</h1>
        <ul>
          {posts.map((p: any) => (
            <li key={p.link}>
              <Link to={p.link}>{p.title}</Link>
            </li>
          ))}
        </ul>
      </main>
    );
  }
  return (
    <main>
      <Outlet />
    </main>
  );
}
