import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedCsvFile {
  final String name;
  final Uint8List bytes;

  const PickedCsvFile({
    required this.name,
    required this.bytes,
  });
}

class FilePickerService {
  Future<PickedCsvFile?> pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    return PickedCsvFile(
      name: file.name,
      bytes: bytes,
    );
  }
}
