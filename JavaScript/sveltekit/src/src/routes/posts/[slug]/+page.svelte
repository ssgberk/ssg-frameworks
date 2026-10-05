<script>
  let { data } = $props();
  const Content = $derived(data.content);
</script>

<svelte:head><title>{data.title}</title></svelte:head>
<h1>{data.title}</h1>
<Content />
