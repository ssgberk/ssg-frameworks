<script setup>
import { data as posts } from './posts.data.js';
</script>

# SSGBerk VitePress

<ul>
  <li v-for="post in posts" :key="post.url"><a :href="post.url">{{ post.title }}</a></li>
</ul>
