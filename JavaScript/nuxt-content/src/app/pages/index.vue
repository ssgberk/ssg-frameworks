<script setup lang="ts">
const { data: posts } = await useAsyncData('posts', () => queryCollection('posts').order('path', 'ASC').all());
</script>

<template>
  <main>
    <h1>Posts</h1>
    <ul>
      <li v-for="post in posts" :key="post.path"><NuxtLink :to="post.path">{{ post.title }}</NuxtLink></li>
    </ul>
  </main>
</template>
