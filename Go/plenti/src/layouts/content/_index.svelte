<script>
  import { isoDate, ymd } from '../scripts/format.svelte';

  export let title, allContent;

  $: posts = allContent
    .filter((c) => c.type == 'post')
    .sort((a, b) => new Date(b.fields.date) - new Date(a.fields.date));
</script>

<section class="posts" id="posts">
  <h1 class="page-title">{title}</h1>
  <ol class="post-list">
    {#each posts as post}
      <li class="post-item">
        <h2 class="post-item-title"><a href="/{post.path.replace(/^\/+/, '')}/">{post.fields.title}</a></h2>
        <time class="post-item-date" datetime={isoDate(post.fields.date)}>{ymd(post.fields.date)}</time>
        <p class="post-item-summary">{post.fields.summary}</p>
      </li>
    {/each}
  </ol>
</section>
