import 'dart:typed_data';

import '../entities/import_entity.dart';
import '../repositories/import_repository.dart';

class RunImport {
  final ImportRepository _importRepository;

  const RunImport(this._importRepository);

  Future<ImportEntity> call({
    required String fileName,
    required Uint8List bytes,
    required DateTime reportingMonth,
  }) {
    return _importRepository.runImport(
      fileName: fileName,
      bytes: bytes,
      reportingMonth: reportingMonth,
    );
  }
}
