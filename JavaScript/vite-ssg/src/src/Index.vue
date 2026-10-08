<script setup>
const slugs = Object.keys(import.meta.glob('./posts/*.md'))
  .map((f) => f.slice(f.lastIndexOf('/') + 1, -3))
  .sort();
</script>

<template>
  <h1>SSGBerk vite-ssg</h1>
  <ul>
    <li v-for="s in slugs" :key="s"><RouterLink :to="'/posts/' + s">{{ s }}</RouterLink></li>
  </ul>
</template>
