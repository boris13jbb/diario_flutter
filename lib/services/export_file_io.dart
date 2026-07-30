import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> writeExportBytes(String fileName, List<int> bytes) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'NotasPro', 'exports'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
  return file.path;
}
