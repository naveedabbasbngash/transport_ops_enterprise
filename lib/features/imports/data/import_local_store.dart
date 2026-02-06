import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import '../domain/entities/import_entity.dart';
import '../domain/entities/import_row_entity.dart';

class ImportLocalStore {
  ImportLocalStore();

  static const _dbName = 'transport_ops_imports.db';
  static const _storeName = 'imports';
  final _importsStore = stringMapStoreFactory.store(_storeName);

  Database? _db;

  Future<void> saveImport(ImportEntity importEntity) async {
    final db = await _database;
    await _importsStore.record(importEntity.id).put(db, _toMap(importEntity));
  }

  Future<List<ImportEntity>> getImportHistory() async {
    final db = await _database;
    final snapshots = await _importsStore.find(
      db,
      finder: Finder(sortOrders: [SortOrder('importedAt', false)]),
    );
    return snapshots.map((snapshot) => _fromMap(snapshot.value)).toList();
  }

  Future<Database> get _database async {
    final cached = _db;
    if (cached != null) return cached;

    if (kIsWeb) {
      _db = await databaseFactoryWeb.openDatabase(_dbName);
      return _db!;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    _db = await databaseFactoryIo.openDatabase(dbPath);
    return _db!;
  }

  Map<String, dynamic> _toMap(ImportEntity entity) {
    return <String, dynamic>{
      'id': entity.id,
      'fileName': entity.fileName,
      'importedAt': entity.importedAt.toIso8601String(),
      'reportingMonth': entity.reportingMonth.toIso8601String(),
      'columnMapping': entity.columnMapping,
      'rows': entity.rows.map(_rowToMap).toList(),
    };
  }

  Map<String, dynamic> _rowToMap(ImportRowEntity row) {
    return <String, dynamic>{
      'rowNumber': row.rowNumber,
      'rawJson': row.rawJson,
      'normalizedJson': row.normalizedJson,
      'status': row.status.name,
      'errorMessage': row.errorMessage,
      'matchedEntityId': row.matchedEntityId,
    };
  }

  ImportEntity _fromMap(Map<String, dynamic> map) {
    final mappingRaw = (map['columnMapping'] as Map?) ?? const {};
    final mapping = mappingRaw.map(
      (key, value) => MapEntry(key.toString(), value?.toString()),
    );

    final rowsRaw = (map['rows'] as List?) ?? const [];
    final rows = rowsRaw.map((item) {
      final rowMap = (item as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final rawJson = ((rowMap['rawJson'] as Map?) ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
      final normalizedRaw = rowMap['normalizedJson'] as Map?;
      return ImportRowEntity(
        rowNumber: (rowMap['rowNumber'] as num?)?.toInt() ?? 0,
        rawJson: rawJson,
        normalizedJson: normalizedRaw?.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        status: _statusFromString((rowMap['status'] ?? '').toString()),
        errorMessage: rowMap['errorMessage']?.toString(),
        matchedEntityId: rowMap['matchedEntityId']?.toString(),
      );
    }).toList();

    return ImportEntity(
      id: (map['id'] ?? '').toString(),
      fileName: (map['fileName'] ?? '').toString(),
      importedAt: DateTime.tryParse((map['importedAt'] ?? '').toString()) ??
          DateTime.now().toUtc(),
      reportingMonth:
          DateTime.tryParse((map['reportingMonth'] ?? '').toString()) ??
              DateTime.now().toUtc(),
      columnMapping: mapping,
      rows: rows,
    );
  }

  ImportRowStatus _statusFromString(String value) {
    for (final status in ImportRowStatus.values) {
      if (status.name == value) return status;
    }
    return ImportRowStatus.error;
  }
}
