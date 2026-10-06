import { readdirSync } from 'node:fs';
import { defineConfig } from 'vite';
import analog from '@analogjs/platform';

// Static prerender of the index and one route per post file, no SSR server.
const posts = readdirSync('src/content/posts')
  .filter((f) => f.endsWith('.md'))
  .map((f) => `/posts/${f.slice(0, -3)}`);

export default defineConfig({
  build: { target: ['es2020'] },
  resolve: { mainFields: ['module'] },
  plugins: [
    analog({
      content: { highlighter: 'prism' },
      ssr: true,
      static: true,
      nitro: { cacheDir: 'node_modules/.cache/nitro' },
      prerender: { routes: ['/', ...posts] },
    }),
  ],
});
