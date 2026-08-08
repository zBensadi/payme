class SyncResult {
  final int uploaded;
  final int downloaded;
  final int skipped;
  final int failed;
  final int conflicts;

  const SyncResult({
    this.uploaded = 0,
    this.downloaded = 0,
    this.skipped = 0,
    this.failed = 0,
    this.conflicts = 0,
  });

  SyncResult copyWith({
    int? uploaded,
    int? downloaded,
    int? skipped,
    int? failed,
    int? conflicts,
  }) {
    return SyncResult(
      uploaded: uploaded ?? this.uploaded,
      downloaded: downloaded ?? this.downloaded,
      skipped: skipped ?? this.skipped,
      failed: failed ?? this.failed,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}
