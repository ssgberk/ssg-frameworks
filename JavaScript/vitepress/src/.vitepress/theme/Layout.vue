<template>
  <main>
    <h1 v-if="$frontmatter.title">{{ $frontmatter.title }}</h1>
    <Content />
  </main>
</template>
