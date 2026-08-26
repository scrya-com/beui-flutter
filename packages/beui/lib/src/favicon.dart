/// Resolve a website URL to its conventional root favicon.
/// Port of `lib/favicon.ts` `getFaviconUrl`.
String? beuiFaviconUrl(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    final uri = Uri.parse(value);
    if (uri.host.isEmpty) return null;
    return Uri(
      scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: '/favicon.ico',
    ).toString();
  } catch (_) {
    return null;
  }
}

/// CORS-friendly fallback so Flutter web/canvaskit can still paint the glyph
/// when `/favicon.ico` is 403/404 or blocked. React's `<img>` does not need this.
String? beuiFaviconFallbackUrl(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    final host = Uri.parse(value).host;
    if (host.isEmpty) return null;
    return 'https://www.google.com/s2/favicons?sz=32&domain=${Uri.encodeQueryComponent(host)}';
  } catch (_) {
    return null;
  }
}
