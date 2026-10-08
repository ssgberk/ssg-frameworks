import { defineConfig } from '@docmd/core';
export default defineConfig({
  title: 'SSGBerk docmd',
  src: 'docs',
  out: 'site',
  layout: { spa: false, copyCode: false, copyWidgets: false, breadcrumbs: false, pageNavigation: false,
    sidebar: { enabled: false }, header: { enabled: false },
    footer: { branding: false, copyright: '' },
    optionsMenu: { components: { search: false, themeSwitch: false, focusMode: false } } },
  navigation: [],
  plugins: { search: false, seo: false, sitemap: false, analytics: false, llms: false, mermaid: false, git: false, openapi: false, okf: false, ai: false },
});
