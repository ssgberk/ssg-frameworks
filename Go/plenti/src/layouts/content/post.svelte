<script>
  import { renderMarkdown } from '../scripts/markdown.svelte';
  import { isoDate, ymd } from '../scripts/format.svelte';

  export let title, date, author, tags, body;
</script>

<article class="post">
  <h1 class="post-title">{title}</h1>
  <p class="post-meta"><time class="post-date" datetime={isoDate(date)}>{ymd(date)}</time> by <span class="post-author">{author}</span></p>
  <ul class="post-tags">
    {#each tags as tag}
      <li class="post-tag">{tag}</li>
    {/each}
  </ul>
  <div class="post-body">
    {@html renderMarkdown(body)}
  </div>
</article>
