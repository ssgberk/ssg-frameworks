<script>
  export let kind;
</script>

<header class="site-header">
  <a class="site-title" href="/">SSGBerk Reference</a>
  <nav class="site-nav">
    <ul>
      <li><a href="/" aria-current={kind == 'index' ? 'page' : undefined}>Home</a></li>
      <li><a href="/#posts">Posts</a></li>
      <li><a href="https://github.com/ssgberk">Source</a></li>
    </ul>
  </nav>
</header>
