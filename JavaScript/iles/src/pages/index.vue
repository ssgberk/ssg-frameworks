<script setup>
const mods = import.meta.glob('./posts/*.md', { eager: true })
const list = Object.entries(mods)
  .map(([file, m]) => ({ url: `/posts/${file.slice(8, -3)}`, title: m.default.frontmatter?.title }))
  .sort((a, b) => a.url.localeCompare(b.url))
</script>
<template><h1>SSGBerk îles</h1><ul><li v-for="p in list" :key="p.url"><a :href="p.url">{{ p.title }}</a></li></ul></template>
