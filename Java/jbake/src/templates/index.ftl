<#include "header.ftl">
<section class="posts" id="posts">
<h1 class="page-title">Posts</h1>
<ol class="post-list">
<#list published_posts as post>
<li class="post-item">
<h2 class="post-item-title"><a href="${post.uri}">${post.title}</a></h2>
<time class="post-item-date" datetime="${post.date?string("yyyy-MM-dd'T'HH:mm:ss'Z'")}">${post.date?string("yyyy-MM-dd")}</time>
<p class="post-item-summary">${post.summary!""}</p>
</li>
</#list>
</ol>
</section>
<#include "footer.ftl">
