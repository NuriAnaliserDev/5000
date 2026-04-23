/// Vertex AI [InlineDataPart] uchun rasm MIME turini aniqlash.
String mimeTypeForImagePath(String path) {
  final lower = path.split('?').first.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.heif')) return 'image/heif';
  return 'image/jpeg';
}

/// HTTP [Content-Type] sarlavhasidan image/* ajratish.
String? mimeTypeFromContentTypeHeader(String? header) {
  if (header == null || header.isEmpty) return null;
  final part = header.split(';').first.trim().toLowerCase();
  if (part.startsWith('image/')) return part;
  return null;
}
