enum ImportRowStatus {
  newRow,
  updatedNotApplied,
  needsReview,
  skipped,
  error,
}

class ImportRowEntity {
  final int rowNumber;
  final Map<String, String> rawJson;
  final Map<String, dynamic>? normalizedJson;
  final ImportRowStatus status;
  final String? errorMessage;
  final String? matchedEntityId;

  const ImportRowEntity({
    required this.rowNumber,
    required this.rawJson,
    required this.normalizedJson,
    required this.status,
    this.errorMessage,
    this.matchedEntityId,
  });
}
