---
title: SSGBerk Observable Framework
---

# SSGBerk Observable Framework

```js
const posts = await FileAttachment("posts.json").json();
display(html`<ul>${posts.map((p) => html`<li><a href="${p.path}">${p.title}</a></li>`)}</ul>`);
```
