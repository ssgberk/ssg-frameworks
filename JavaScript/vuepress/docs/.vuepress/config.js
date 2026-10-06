import { viteBundler } from '@vuepress/bundler-vite';
import { defineUserConfig } from 'vuepress';
import localTheme from './theme/index.js';

export default defineUserConfig({
  title: 'SSGBerk VuePress',
  bundler: viteBundler(),
  theme: localTheme(),
  head: [],
});
