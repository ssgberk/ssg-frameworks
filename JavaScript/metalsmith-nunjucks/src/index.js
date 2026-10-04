import Metalsmith from 'metalsmith'
import markdown from '@metalsmith/markdown'
import permalinks from '@metalsmith/permalinks'
import layouts from '@metalsmith/layouts'
import { dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

// Writes one index page listing every post.
const indexPage = (files) => {
  const posts = Object.keys(files)
    .filter((f) => f.startsWith('posts/') && f.endsWith('/index.html'))
    .sort()
    .map((f) => ({ title: files[f].title, url: '/' + f.replace(/index\.html$/, '') }))
  files['index.html'] = { contents: Buffer.from(''), title: 'Posts', layout: 'index.njk', posts }
}

Metalsmith(dirname(fileURLToPath(import.meta.url)))
  .source('./content')
  .destination('./build')
  .clean(true)
  .use(markdown())
  .use(permalinks({ pattern: 'posts/:title' }))
  .use(indexPage)
  .use(layouts({ pattern: '**/*.html', transform: 'nunjucks', directory: 'layouts', default: 'post.njk' }))
  .build((err) => { if (err) { console.error(err); process.exit(1) } })
