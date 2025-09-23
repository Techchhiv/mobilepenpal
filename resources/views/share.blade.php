// resources/views/share/product.blade.php
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{{ $title }}</title>
  <meta name="description" content="{{ $desc }}">
  <link rel="canonical" href="{{ $redirect }}"/>

  <!-- Open Graph -->
  <meta property="og:type" content="product"/>
  <meta property="og:title" content="{{ $title }}"/>
  <meta property="og:description" content="{{ $desc }}"/>
  <meta property="og:image" content="{{ $image }}"/>
  <meta property="og:url" content="{{ $redirect }}"/>

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image"/>
  <meta name="twitter:title" content="{{ $title }}"/>
  <meta name="twitter:description" content="{{ $desc }}"/>
  <meta name="twitter:image" content="{{ $image }}"/>

  <meta http-equiv="refresh" content="0;url={{ $redirect }}">
  <script>location.replace(@json($redirect));</script>
</head>
<body></body>
</html>
