import { defineConfig } from '@rspress/core';

export default defineConfig({
  root: 'docs',
  outDir: 'doc_build',
  title: 'SSGBerk Rspress',
  search: false,
  llms: false,
  themeConfig: { darkMode: false },
});
