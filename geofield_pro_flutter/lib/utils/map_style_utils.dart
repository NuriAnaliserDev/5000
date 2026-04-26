class MapStyleUtils {
  static String getUrlTemplate(String style) {
    if (style == 'opentopomap') {
      return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    } else if (style == 'satellite') {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  static List<String> getSubdomains(String style) {
    if (style == 'opentopomap') return ['a', 'b', 'c'];
    if (style == 'satellite') return []; // ArcGIS doesn't use standard abc
    return ['a', 'b', 'c'];
  }
}
