import 'dart:typed_data';

import 'package:veil/src/features/social/models/social_entry/social_entry.dart';

enum LetterboxdImportSource { activity, watchlist }

class LetterboxdImportFile {
  const LetterboxdImportFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

class LetterboxdImportRow {
  const LetterboxdImportRow({
    required this.source,
    required this.sourceFile,
    required this.entry,
  });

  final LetterboxdImportSource source;
  final String sourceFile;
  final SocialEntry entry;
}

class LetterboxdImportPreview {
  const LetterboxdImportPreview({
    required this.rows,
    required this.skippedCount,
    required this.unsupportedCount,
    required this.warnings,
  });

  final List<LetterboxdImportRow> rows;
  final int skippedCount;
  final int unsupportedCount;
  final List<String> warnings;

  int get totalRows => rows.length;

  int get activityCount =>
      rows.where((row) => row.source == LetterboxdImportSource.activity).length;

  int get watchlistCount => rows
      .where((row) => row.source == LetterboxdImportSource.watchlist)
      .length;

  List<SocialEntry> get entries => rows.map((row) => row.entry).toList();

  bool get isEmpty => rows.isEmpty;
}

class LetterboxdExportBundle {
  const LetterboxdExportBundle({
    required this.fileName,
    required this.bytes,
    required this.activityCount,
    required this.watchlistCount,
    required this.unsupportedCount,
  });

  final String fileName;
  final Uint8List bytes;
  final int activityCount;
  final int watchlistCount;
  final int unsupportedCount;
}
