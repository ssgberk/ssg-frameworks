<script setup>
import { useHead } from '@unhead/vue';

const props = defineProps({ frontmatter: { type: Object, default: () => ({}) } });
useHead({ title: props.frontmatter.title });
</script>

<template>
  <article class="post">
    <h1 class="post-title">{{ frontmatter.title }}</h1>
    <div class="post-body"><slot /></div>
  </article>
</template>
