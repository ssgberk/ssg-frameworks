import { ViteSSG } from 'vite-ssg';
import App from './App.vue';
import Post from './Post.vue';

const modules = import.meta.glob('./posts/*.md');
const routes = [
  { path: '/', component: () => import('./Index.vue') },
  ...Object.entries(modules).map(([file, load]) => ({
    path: '/posts/' + file.slice(file.lastIndexOf('/') + 1, -3),
    component: load,
  })),
];

export const createApp = ViteSSG(App, { routes }, ({ app }) => {
  app.component('Post', Post);
});
