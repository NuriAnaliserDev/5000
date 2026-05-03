/// Oflayn xarita — URL va subdomenlar; [GlobalMapScreen] kabi ekranlarda qayta ishlatish.
String mapTileUrlTemplate(String style) {
  return switch (style) {
    'osm' => 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    'satellite' =>
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    _ => 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
  };
}

List<String> mapTileSubdomains(String style) {
  if (style == 'satellite') return const [];
  if (style == 'osm') return const ['a', 'b', 'c', 'd'];
  return const ['a', 'b', 'c'];
}
