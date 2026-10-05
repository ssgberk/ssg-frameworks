<script setup lang="ts">
const route = useRoute();
const { data: post } = await useAsyncData(route.path, () => queryCollection('posts').path(route.path).first());
if (!post.value) throw createError({ statusCode: 404, statusMessage: 'Post not found', fatal: true });
</script>

<template>
  <main v-if="post">
    <h1>{{ post.title }}</h1>
    <ContentRenderer :value="post" />
  </main>
</template>
