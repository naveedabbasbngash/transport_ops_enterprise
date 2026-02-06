import 'dart:typed_data';

import '../entities/import_entity.dart';

abstract class ImportRepository {
  Future<ImportEntity> runImport({
    required String fileName,
    required Uint8List bytes,
    required DateTime reportingMonth,
  });

  Future<List<ImportEntity>> getImportHistory();
}
