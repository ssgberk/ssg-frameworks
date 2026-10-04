@extends('_layouts.master')

@section('body')

<div class="post">

  <header class="post-header">
    <h1 class="post-title">{{ $page->title }}</h1>
    <p class="post-meta">{{ $page->dateFormatted() }}</p>
  </header>

  <article class="post-main">
     @yield('content')
  </article>

</div>

@endsection
