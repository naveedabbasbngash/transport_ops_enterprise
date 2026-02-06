List<Map<String, dynamic>> extractListFromResponse(
  Map<String, dynamic> body,
) {
  dynamic data = body['data'];
  if (data is List) {
    return data
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  if (data is Map) {
    final nested = data['data'];
    if (nested is List) {
      return nested
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    final items = data['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
  }

  final rootItems = body['items'];
  if (rootItems is List) {
    return rootItems
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  return const <Map<String, dynamic>>[];
}
