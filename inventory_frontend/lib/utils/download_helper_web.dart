// Web implementation uses dart:html to trigger a download
import 'dart:convert';
import 'dart:html' as html;

Future<void> saveFileBytes(List<int> bytes, String fileName) async {
  final content = base64Encode(bytes);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = 'data:application/octet-stream;base64,$content';
  anchor.download = fileName;
  anchor.style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
