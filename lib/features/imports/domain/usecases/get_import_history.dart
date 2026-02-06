import '../entities/import_entity.dart';
import '../repositories/import_repository.dart';

class GetImportHistory {
  final ImportRepository _importRepository;

  const GetImportHistory(this._importRepository);

  Future<List<ImportEntity>> call() {
    return _importRepository.getImportHistory();
  }
}
