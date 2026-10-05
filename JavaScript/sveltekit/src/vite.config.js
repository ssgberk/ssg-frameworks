import adapter from '@sveltejs/adapter-static';
import { sveltekit } from '@sveltejs/kit/vite';
import { mdsvex } from 'mdsvex';
import { defineConfig } from 'vite';

// SvelteKit 3 reads its configuration from the sveltekit() plugin (svelte.config.js is rejected).
export default defineConfig({
  plugins: [
    sveltekit({
      extensions: ['.svelte', '.md'],
      preprocess: [mdsvex({ extensions: ['.md'] })],
      adapter: adapter({ pages: 'build', assets: 'build', strict: true }),
    }),
  ],
});
