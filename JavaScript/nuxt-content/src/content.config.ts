import { defineCollection, defineContentConfig, z } from '@nuxt/content';

export default defineContentConfig({
  collections: {
    posts: defineCollection({
      type: 'page',
      source: { include: 'posts/*.md', prefix: '/posts' },
      schema: z.object({ date: z.coerce.string() }),
    }),
  },
});
