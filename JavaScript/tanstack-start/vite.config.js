import { tanstackStart } from '@tanstack/react-start/plugin/vite';
import viteReact from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// Static prerender: every route reachable from "/" is rendered to HTML at build time.
// The prerender step fetches pages from a Vite preview server; binding it to 127.0.0.1 avoids "localhost"
// resolving to an IPv6 address the container cannot reach (ECONNREFUSED on CI runners).
export default defineConfig({
  preview: { host: '127.0.0.1' },
  plugins: [
    tanstackStart({
      prerender: { enabled: true, crawlLinks: true, autoSubfolderIndex: true, failOnError: true },
    }),
    viteReact(),
  ],
});
