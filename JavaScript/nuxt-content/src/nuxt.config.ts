export default defineNuxtConfig({
  modules: ['@nuxt/content'],
  telemetry: false,
  devtools: { enabled: false },
  content: { experimental: { sqliteConnector: 'native' } },
  app: { head: { title: 'Posts' } },
});
