import { defineConfig } from 'iles'
import remarkGfm from 'remark-gfm'

export default defineConfig({ srcDir: '.', markdown: { remarkPlugins: [remarkGfm] } })
