<script setup>
import { usePage } from 'iles'
const { frontmatter } = usePage()
</script>
<template><main><h1 v-if="frontmatter.title">{{ frontmatter.title }}</h1><slot /></main></template>
