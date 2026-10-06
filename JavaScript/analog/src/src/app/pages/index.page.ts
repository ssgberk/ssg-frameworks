import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { injectContentFiles } from '@analogjs/content';

import PostAttributes from '../post-attributes';

@Component({
  selector: 'app-index',
  imports: [RouterLink],
  template: `
    <h1>Posts</h1>
    <ul>
      @for (post of posts; track post.slug) {
      <li><a [routerLink]="['/posts', post.slug]">{{ post.slug }}</a></li>
      }
    </ul>
  `,
})
export default class Index {
  readonly posts = injectContentFiles<PostAttributes>();
}
