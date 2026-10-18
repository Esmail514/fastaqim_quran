/// Keep the marker paths and their original ancestor transforms in the pinned
/// Madinah Warsh SVG format. No coordinates or number glyphs are reconstructed.
String warshMarkerSvg(String source) {
  final root = RegExp(r'<svg\b[^>]*>').firstMatch(source);
  if (root == null) throw const FormatException('Missing Warsh SVG root.');
  final result = StringBuffer(root.group(0)!);
  var depth = 0;
  int? markerDepth;
  var cursor = root.end;
  var found = false;
  for (final match in RegExp(r'</?g\b[^>]*>').allMatches(source, root.end)) {
    if (markerDepth != null) {
      result.write(source.substring(cursor, match.start));
    }
    final tag = match.group(0)!;
    result.write(tag);
    if (tag.startsWith('</')) {
      if (depth == markerDepth) markerDepth = null;
      depth--;
    } else if (!tag.endsWith('/>')) {
      depth++;
      if (RegExp(r'''\bid\s*=\s*["']ayah_markers["']''').hasMatch(tag)) {
        markerDepth = depth;
        found = true;
      }
    }
    cursor = match.end;
  }
  if (!found || depth != 0 || markerDepth != null) {
    throw const FormatException('Missing or invalid Warsh marker layer.');
  }
  result.write('</svg>');
  return result.toString();
}
