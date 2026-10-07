import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// Mobile / desktop: hand the file to the system share sheet.
Future<void> saveFile(String name, Uint8List bytes, String mime) async {
  await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: name, mimeType: mime)], fileNameOverrides: [name], title: name));
}
