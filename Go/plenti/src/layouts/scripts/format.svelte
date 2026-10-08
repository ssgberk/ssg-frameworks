<script context="module">
  export const isoDate = (d) => new Date(d).toISOString().replace(/\.\d{3}Z$/, 'Z');
  export const ymd = (d) => new Date(d).toISOString().slice(0, 10);
</script>
