<script>
  import Head from './head.svelte';
  import Header from './header.svelte';
  import Footer from './footer.svelte';

  export let content, layout, allContent;

  const kind = content.type == '_index' ? 'index' : content.type == '404' ? '404' : 'post';
  const title = kind == 'index' ? 'SSGBerk Reference'
    : kind == '404' ? 'Page not found | SSGBerk Reference'
    : content.fields.title + ' | SSGBerk Reference';
</script>

<html lang="en">
  <Head {title} />
  <body>
    <Header {kind} />
    <main class="site-main">
      <svelte:component this={layout} {...content.fields} {content} {allContent} />
    </main>
    <Footer />
  </body>
</html>
