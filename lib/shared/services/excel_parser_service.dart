import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

class ParsedCsvData {
  final List<String> headers;
  final List<Map<String, String>> rows;

  const ParsedCsvData({
    required this.headers,
    required this.rows,
  });
}

class CsvParserService {
  ParsedCsvData parse({
    required Uint8List bytes,
    required String fileName,
  }) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')) {
      return _parseExcel(bytes);
    }
    return _parseCsv(bytes);
  }

  ParsedCsvData _parseCsv(Uint8List bytes) {
    final rawContent = utf8.decode(bytes, allowMalformed: true);
    final content = rawContent.startsWith('\uFEFF')
        ? rawContent.substring(1)
        : rawContent;

    final matrix = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(content);

    if (matrix.isEmpty) {
      return const ParsedCsvData(headers: <String>[], rows: <Map<String, String>>[]);
    }

    final headers = matrix.first
        .map((column) => (column ?? '').toString())
        .toList(growable: false);

    final rows = <Map<String, String>>[];
    for (var rowIndex = 1; rowIndex < matrix.length; rowIndex++) {
      final row = matrix[rowIndex];
      final rawMap = <String, String>{};
      for (var colIndex = 0; colIndex < headers.length; colIndex++) {
        final header = headers[colIndex];
        final value = colIndex < row.length ? row[colIndex] : '';
        rawMap[header] = (value ?? '').toString();
      }
      rows.add(Map.unmodifiable(rawMap));
    }

    return ParsedCsvData(
      headers: headers,
      rows: rows,
    );
  }

  ParsedCsvData _parseExcel(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return const ParsedCsvData(headers: <String>[], rows: <Map<String, String>>[]);
    }

    final firstSheetName = workbook.tables.keys.first;
    final firstSheet = workbook.tables[firstSheetName];
    if (firstSheet == null || firstSheet.rows.isEmpty) {
      return const ParsedCsvData(headers: <String>[], rows: <Map<String, String>>[]);
    }

    final headerCells = firstSheet.rows.first;
    final headers = headerCells
        .map((cell) => cell?.value?.toString() ?? '')
        .toList(growable: false);

    final rows = <Map<String, String>>[];
    for (var rowIndex = 1; rowIndex < firstSheet.rows.length; rowIndex++) {
      final cells = firstSheet.rows[rowIndex];
      final rawMap = <String, String>{};
      for (var colIndex = 0; colIndex < headers.length; colIndex++) {
        final header = headers[colIndex];
        final cell = colIndex < cells.length ? cells[colIndex] : null;
        final value = cell?.value?.toString() ?? '';
        rawMap[header] = value;
      }
      rows.add(Map.unmodifiable(rawMap));
    }

    return ParsedCsvData(
      headers: headers,
      rows: rows,
    );
  }
}
