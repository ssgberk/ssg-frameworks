import { Component } from '@angular/core';
import { AsyncPipe } from '@angular/common';
import { injectContent, MarkdownComponent } from '@analogjs/content';

import PostAttributes from '../../post-attributes';

@Component({
  selector: 'app-post',
  imports: [AsyncPipe, MarkdownComponent],
  template: `
    @if (post$ | async; as post) {
    <article>
      <h1>{{ post.attributes.title }}</h1>
      <analog-markdown [content]="post.content" />
    </article>
    }
  `,
})
export default class Post {
  readonly post$ = injectContent<PostAttributes>({ param: 'slug', subdirectory: 'posts' });
}
