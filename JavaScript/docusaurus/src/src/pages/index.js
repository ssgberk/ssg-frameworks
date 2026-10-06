import React from 'react';
import {usePluginData} from '@docusaurus/useGlobalData';

export default function Home() {
  const posts = usePluginData('ssgberk-post-list') || [];
  return (
    <>
      <h1>SSGBerk Docusaurus</h1>
      <ul>
        {posts.map((p) => (
          <li key={p.permalink}><a href={p.permalink}>{p.title}</a></li>
        ))}
      </ul>
    </>
  );
}
