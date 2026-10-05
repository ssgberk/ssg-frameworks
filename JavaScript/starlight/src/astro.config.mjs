import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  trailingSlash: 'always',
  build: { format: 'directory' },
  integrations: [
    starlight({
      title: 'SSGBerk',
      pagefind: false,
      tableOfContents: false,
      pagination: false,
      sidebar: [],
      components: { Sidebar: './src/components/Empty.astro' },
    }),
  ],
});
