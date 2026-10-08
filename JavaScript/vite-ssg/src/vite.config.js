import { defineConfig } from 'vite';
import Vue from '@vitejs/plugin-vue';
import Markdown from 'unplugin-vue-markdown/vite';

export default defineConfig({
  plugins: [
    Vue({ include: [/\.vue$/, /\.md$/] }),
    Markdown({ headEnabled: false }),
  ],
});
