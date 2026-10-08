<#include "header.ftl">
<article class="post">
<h1 class="post-title">${content.title}</h1>
<p class="post-meta"><time class="post-date" datetime="${content.date?string("yyyy-MM-dd'T'HH:mm:ss'Z'")}">${content.date?string("yyyy-MM-dd")}</time> by <span class="post-author">${content.author!""}</span></p>
<#if content.tags?? && content.tags?has_content>
<ul class="post-tags">
<#list content.tags as tag>
<li class="post-tag">${tag}</li>
</#list>
</ul>
</#if>
<div class="post-body">
${content.body}
</div>
</article>
<#include "footer.ftl">
