<script setup>
import { computed } from 'vue';
import { Content, usePageData, usePageFrontmatter } from 'vuepress/client';
import posts from '@temp/posts.js';

const page = usePageData();
const frontmatter = usePageFrontmatter();
const isHome = computed(() => page.value.path === '/');
</script>

<template>
  <main>
    <h1 v-if="frontmatter.title">{{ frontmatter.title }}</h1>
    <Content />
    <ul v-if="isHome">
      <li v-for="post in posts" :key="post.path"><a :href="post.path">{{ post.title }}</a></li>
    </ul>
  </main>
</template>
