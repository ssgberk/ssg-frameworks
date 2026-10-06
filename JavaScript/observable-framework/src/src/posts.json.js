import {readdirSync, readFileSync} from 'node:fs';

const dir = new URL('./posts/', import.meta.url);
const posts = readdirSync(dir)
  .filter((f) => f.endsWith('.md'))
  .sort()
  .map((f) => {
    const m = /^title: (.*)$/m.exec(readFileSync(new URL(f, dir), 'utf8'));
    return {path: `/posts/${f.slice(0, -3)}`, title: m ? m[1] : f};
  });
process.stdout.write(JSON.stringify(posts));
