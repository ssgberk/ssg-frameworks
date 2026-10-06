---
title: SSGBerk Observable Framework
---

# SSGBerk Observable Framework

```js
const posts = await FileAttachment("posts.json").json();
const list = document.createElement("ul");
for (const p of posts) {
  const li = list.appendChild(document.createElement("li"));
  const a = li.appendChild(document.createElement("a"));
  a.href = p.path;
  a.textContent = p.title;
}
display(list);
```
