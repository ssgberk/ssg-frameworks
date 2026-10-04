export default function (eleventyConfig) {
  eleventyConfig.ignores.add('README.md');
  return { dir: { input: '.', includes: '_includes', output: '_site' } };
}
