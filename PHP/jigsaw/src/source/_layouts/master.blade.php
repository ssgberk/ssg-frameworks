<!DOCTYPE html>
<html>
  <head>
     <meta charset="utf-8">
     <title>{{ $page->title }} | {{ $page->siteTitle }}</title>

     <!-- CSS -->
     <link rel="stylesheet" href="/css/style.css">
  </head>
  <body>
    @include('_includes.header')
    <div class="main">
       @yield('body')
    </div>
    @include('_includes.footer')
  </body>
</html>
