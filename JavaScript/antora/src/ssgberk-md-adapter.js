'use strict'

// Antora extension for the SSGBerk benchmark. Antora only reads AsciiDoc, while build.sh writes the
// canonical markdown posts. This runs once, inside the Antora process (no per-post forks), right after
// the content aggregate is loaded: every pages/**/*.md file becomes an in-memory .adoc page and a
// generated index page links all of them. Handles the constructs of the reference content (spec 005).

const BASENAME = (p) => p.slice(p.lastIndexOf('/') + 1)

function inline (text) {
  const spans = []
  text = text.replace(/`[^`]*`/g, (m) => '\u0000' + (spans.push(m) - 1) + '\u0000')
  text = text
    .replace(/\[([^\]]*)\]\(([^)\s]*)\)/g, '$2[$1]')
    .replace(/\*\*([^*]+)\*\*/g, '\u0001$1\u0001')
    .replace(/\*([^*]+)\*/g, '__$1__')
    .replace(/\u0001/g, '**')
  return text.replace(/\u0000(\d+)\u0000/g, (_, i) => spans[i])
}

function convert (md, title) {
  const out = ['= ' + title, ':page-layout: default', '']
  const lines = md.split('\n')
  let i = 0
  while (i < lines.length) {
    const line = lines[i]
    let m
    if (line.trim() === '') { out.push(''); i++ } else if ((m = /^(#{1,6})\s+(.*)$/.exec(line))) {
      out.push('='.repeat(m[1].length) + ' ' + inline(m[2])); i++
    } else if (/^~~~|^```/.test(line)) {
      const fence = line.slice(0, 3)
      const lang = line.slice(3).trim()
      out.push('[source' + (lang ? ',' + lang : '') + ']', '----')
      i++
      while (i < lines.length && !lines[i].startsWith(fence)) out.push(lines[i++])
      out.push('----'); i++
    } else if (/^(\*\s*){3,}$|^(-\s*){3,}$/.test(line)) {
      out.push("'''"); i++
    } else if (line.startsWith('>')) {
      out.push('[quote]', '____')
      while (i < lines.length && lines[i].startsWith('>')) out.push(inline(lines[i++].replace(/^>\s?/, '')))
      out.push('____')
    } else if (line.startsWith('|')) {
      const cells = (l) => l.replace(/^\||\|\s*$/g, '').split('|').map((c) => '|' + inline(c.trim())).join(' ')
      out.push('[options="header"]', '|===', cells(line)); i += 2
      while (i < lines.length && lines[i].startsWith('|')) out.push(cells(lines[i++]))
      out.push('|===')
    } else if ((m = /^!\[([^\]]*)\]\(([^)]*)\)\s*$/.exec(line))) {
      out.push('image::' + BASENAME(m[2]) + '[' + m[1] + ']'); i++
    } else if ((m = /^(\s*)([-*+]|\d+\.)\s+(.*)$/.exec(line))) {
      const depth = Math.floor(m[1].length / 4) + 1
      out.push((/\d/.test(m[2]) ? '.' : '*').repeat(depth) + ' ' + inline(m[3])); i++
    } else {
      out.push(inline(line)); i++
    }
  }
  return out.join('\n') + '\n'
}

module.exports.register = function () {
  this.once('contentAggregated', ({ contentAggregate }) => {
    for (const bucket of contentAggregate) {
      const posts = []
      for (const file of bucket.files) {
        if (!file.src.path.startsWith('modules/ROOT/pages/') || file.src.extname !== '.md') continue
        const stem = file.src.stem
        const title = 'Post ' + stem.slice(stem.lastIndexOf('-') + 1)
        file.contents = Buffer.from(convert(file.contents.toString(), title))
        const adoc = (p) => p.slice(0, -3) + '.adoc'
        file.path = adoc(file.path)
        file.src.path = adoc(file.src.path)
        file.src.basename = stem + '.adoc'
        file.src.extname = '.adoc'
        posts.push({ stem, title, file })
      }
      if (!posts.length) continue
      posts.sort((a, b) => (a.stem < b.stem ? 1 : -1))
      const lines = ['= Posts', '']
      for (const { stem, title } of posts) lines.push('* xref:posts/' + stem + '.adoc[' + title + ']')
      const first = posts[0].file
      const dir = first.path.slice(0, first.path.length - 'posts/'.length - first.src.basename.length)
      bucket.files.push(Object.assign(Object.create(Object.getPrototypeOf(first)), first, {
        history: [first.path],
        path: dir + 'index.adoc',
        contents: Buffer.from(lines.join('\n') + '\n'),
        src: Object.assign({}, first.src, { path: 'modules/ROOT/pages/index.adoc', basename: 'index.adoc', stem: 'index', extname: '.adoc' }),
      }))
    }
  })
}
