import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:veil/src/features/letterboxd/models/letterboxd_import_export.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/shared/utils/veil_rating.dart';

class LetterboxdImportExportService {
  const LetterboxdImportExportService();

  LetterboxdExportBundle buildExport(List<SocialEntry> entries) {
    final movieEntries = entries.where(_isMovie).toList();
    final unsupported = entries.where((entry) => !_isMovie(entry)).toList();
    final activity = movieEntries.where(_hasActivity).toList();
    final watchlist = movieEntries
        .where((entry) => entry.inWatchlist && !_hasActivity(entry))
        .toList();

    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'veil-letterboxd-activity.csv',
          _activityCsv(activity),
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'veil-letterboxd-watchlist.csv',
          _watchlistCsv(watchlist),
        ),
      );

    if (unsupported.isNotEmpty) {
      archive.addFile(
        ArchiveFile.string(
          'veil-letterboxd-skipped.csv',
          _skippedCsv(unsupported),
        ),
      );
    }

    return LetterboxdExportBundle(
      fileName: 'veil-letterboxd-export.zip',
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      activityCount: activity.length,
      watchlistCount: watchlist.length,
      unsupportedCount: unsupported.length,
    );
  }

  LetterboxdImportPreview parseImportFiles(List<LetterboxdImportFile> files) {
    final expandedFiles = <LetterboxdImportFile>[];
    final warnings = <String>[];

    for (final file in files) {
      final name = file.name.toLowerCase();
      if (name.endsWith('.zip')) {
        try {
          final archive = ZipDecoder().decodeBytes(file.bytes);
          for (final archiveFile in archive.files) {
            if (!archiveFile.isFile ||
                !archiveFile.name.toLowerCase().endsWith('.csv')) {
              continue;
            }
            expandedFiles.add(
              LetterboxdImportFile(
                name: archiveFile.name,
                bytes: archiveFile.readBytes() ?? const [],
              ),
            );
          }
        } catch (_) {
          warnings.add('${file.name} could not be opened as a zip.');
        }
      } else if (name.endsWith('.csv')) {
        expandedFiles.add(file);
      }
    }

    if (expandedFiles.isEmpty) {
      return LetterboxdImportPreview(
        rows: const [],
        skippedCount: 0,
        unsupportedCount: 0,
        warnings: [...warnings, 'No CSV files were found.'],
      );
    }

    final rows = <LetterboxdImportRow>[];
    var skippedCount = 0;
    var unsupportedCount = 0;

    for (final file in expandedFiles) {
      final csv = utf8.decode(file.bytes, allowMalformed: true);
      final table = _parseCsv(csv);
      if (table.length < 2) continue;

      final headers = _HeaderIndex(table.first);
      for (final values in table.skip(1)) {
        if (values.every((value) => value.trim().isEmpty)) {
          skippedCount++;
          continue;
        }

        final title = headers.first(values, const ['title', 'name', 'film']);
        if (title.trim().isEmpty) {
          skippedCount++;
          continue;
        }

        final mediaType = headers.first(values, const [
          'media type',
          'mediatype',
          'type',
        ]).toLowerCase();
        if (mediaType.contains('tv') ||
            mediaType.contains('show') ||
            mediaType.contains('series')) {
          unsupportedCount++;
          continue;
        }

        final source = _sourceFor(file.name, headers, values);
        final rating = _parseRating(
          headers.first(values, const ['rating', 'rating10']),
        );
        final isWatchlistSource = source == LetterboxdImportSource.watchlist;
        final watchedOn = isWatchlistSource
            ? null
            : _parseDate(
                headers.first(values, const [
                  'watcheddate',
                  'watched date',
                  'date',
                ]),
              );
        final review = headers.first(values, const ['review', 'body']).trim();
        final rewatch = _parseBool(
          headers.first(values, const ['rewatch', 'rewatched']),
        );
        final tags = _mergeTags(
          tags: headers.first(values, const ['tags', 'tag']),
          rewatch: source == LetterboxdImportSource.activity ? rewatch : null,
        );
        final tmdbId = _parseInt(
          headers.first(values, const ['tmdbid', 'tmdb id', 'tmdb']),
        );
        final imdbId = _cleanOptional(
          headers.first(values, const ['imdbid', 'imdb id', 'imdb']),
        );
        final year = _parseInt(headers.first(values, const ['year'])) ?? 0;

        final hasActivity =
            !isWatchlistSource &&
            (source == LetterboxdImportSource.activity ||
                rating > 0 ||
                review.isNotEmpty ||
                watchedOn != null);
        final importedWatchedOn = hasActivity
            ? watchedOn ?? DateTime.now()
            : null;

        rows.add(
          LetterboxdImportRow(
            source: hasActivity
                ? LetterboxdImportSource.activity
                : LetterboxdImportSource.watchlist,
            sourceFile: file.name,
            entry: SocialEntry(
              id: _entryId(
                title: title,
                year: year,
                tmdbId: tmdbId,
                imdbId: imdbId,
              ),
              userId: 'letterboxd-import',
              tmdbId: tmdbId,
              imdbId: imdbId,
              mediaType: 'movie',
              title: title.trim(),
              year: year,
              type: 'Movie',
              rating: hasActivity ? rating : 0,
              review: hasActivity ? review : '',
              tags: hasActivity ? tags : const [],
              watchedOn: importedWatchedOn,
              inWatchlist: !hasActivity,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );
      }
    }

    return LetterboxdImportPreview(
      rows: rows,
      skippedCount: skippedCount,
      unsupportedCount: unsupportedCount,
      warnings: warnings,
    );
  }
}

String _activityCsv(List<SocialEntry> entries) {
  final rows = [
    const [
      'Title',
      'Year',
      'LetterboxdURI',
      'tmdbID',
      'imdbID',
      'Rating',
      'WatchedDate',
      'Rewatch',
      'Tags',
      'Review',
    ],
    for (final entry in entries)
      [
        _CsvCell(entry.title, forceQuote: true),
        entry.year,
        '',
        entry.tmdbId ?? '',
        entry.imdbId ?? '',
        entry.rating == 0 ? '' : _formatRating(entry.rating),
        entry.watchedOn == null ? '' : _formatDate(entry.watchedOn!),
        entry.tags.contains('rewatch') ? 'true' : '',
        _exportTags(entry.tags),
        entry.review,
      ],
  ];
  return _writeCsv(rows);
}

String _watchlistCsv(List<SocialEntry> entries) {
  final rows = [
    const ['Title', 'Year', 'LetterboxdURI', 'tmdbID', 'imdbID'],
    for (final entry in entries)
      [
        _CsvCell(entry.title, forceQuote: true),
        entry.year,
        '',
        entry.tmdbId ?? '',
        entry.imdbId ?? '',
      ],
  ];
  return _writeCsv(rows);
}

String _skippedCsv(List<SocialEntry> entries) {
  final rows = [
    const ['Title', 'Year', 'MediaType', 'Reason'],
    for (final entry in entries)
      [
        _CsvCell(entry.title, forceQuote: true),
        entry.year,
        entry.mediaType,
        'Letterboxd supports films only',
      ],
  ];
  return _writeCsv(rows);
}

bool _isMovie(SocialEntry entry) {
  final mediaType = entry.mediaType.toLowerCase();
  final type = entry.type.toLowerCase();
  return mediaType == 'movie' || (mediaType.isEmpty && !type.contains('tv'));
}

bool _hasActivity(SocialEntry entry) {
  return entry.watchedOn != null ||
      entry.rating > 0 ||
      entry.review.trim().isNotEmpty;
}

String _writeCsv(List<List<Object?>> rows) {
  return '${rows.map(_writeCsvRow).join('\n')}\n';
}

String _writeCsvRow(List<Object?> cells) {
  return cells
      .map((cell) {
        if (cell is _CsvCell) {
          return _escapeCsv(cell.value, forceQuote: cell.forceQuote);
        }
        return _escapeCsv(cell?.toString() ?? '');
      })
      .join(',');
}

String _escapeCsv(String value, {bool forceQuote = false}) {
  final mustQuote =
      forceQuote ||
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.startsWith(' ') ||
      value.endsWith(' ');
  if (!mustQuote) return value;
  return '"${value.replaceAll('"', '""')}"';
}

String _exportTags(List<String> tags) {
  return tags
      .where((tag) => tag != 'first-time' && tag != 'rewatch')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .join(', ');
}

String _formatRating(double rating) {
  return formatVeilRating(rating);
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

List<List<String>> _parseCsv(String csv) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < csv.length; i++) {
    final char = csv[i];
    if (inQuotes) {
      if (char == '"') {
        final isEscapedQuote = i + 1 < csv.length && csv[i + 1] == '"';
        if (isEscapedQuote) {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }

    if (char == '"') {
      inQuotes = true;
    } else if (char == ',') {
      row.add(field.toString());
      field.clear();
    } else if (char == '\n') {
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else if (char != '\r') {
      field.write(char);
    }
  }

  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

LetterboxdImportSource _sourceFor(
  String fileName,
  _HeaderIndex headers,
  List<String> values,
) {
  final lower = fileName.toLowerCase();
  if (lower.contains('watchlist')) return LetterboxdImportSource.watchlist;
  if (lower.contains('diary') ||
      lower.contains('watched') ||
      lower.contains('rating') ||
      lower.contains('review')) {
    return LetterboxdImportSource.activity;
  }
  final rating = headers.first(values, const ['rating', 'rating10']).trim();
  final review = headers.first(values, const ['review', 'body']).trim();
  final date = headers.first(values, const [
    'watcheddate',
    'watched date',
    'date',
  ]).trim();
  if (rating.isNotEmpty || review.isNotEmpty || date.isNotEmpty) {
    return LetterboxdImportSource.activity;
  }
  return LetterboxdImportSource.watchlist;
}

double _parseRating(String raw) {
  final value = double.tryParse(raw.trim());
  if (value == null || value <= 0) return 0;
  final fiveStarValue = value > 5 ? value / 2 : value;
  return normalizeVeilRating(fiveStarValue, allowUnrated: true);
}

int? _parseInt(String raw) {
  return int.tryParse(raw.trim());
}

DateTime? _parseDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

bool? _parseBool(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) return null;
  if (const {
    'true',
    'yes',
    'y',
    '1',
    'rewatch',
    'watched again',
  }.contains(value)) {
    return true;
  }
  if (const {'false', 'no', 'n', '0'}.contains(value)) return false;
  return null;
}

List<String> _mergeTags({required String tags, required bool? rewatch}) {
  final values = [
    if (rewatch == true) 'rewatch' else if (rewatch == false) 'first-time',
    ...tags.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty),
  ];
  final unique = <String>[];
  for (final value in values) {
    if (!unique.contains(value)) unique.add(value);
  }
  return unique;
}

String? _cleanOptional(String raw) {
  final value = raw.trim();
  return value.isEmpty ? null : value;
}

String _entryId({
  required String title,
  required int year,
  required int? tmdbId,
  required String? imdbId,
}) {
  if (tmdbId != null) return 'movie_$tmdbId';
  if (imdbId != null && imdbId.isNotEmpty) return 'movie_$imdbId';
  final normalized = title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return 'movie_${normalized}_$year';
}

class _CsvCell {
  const _CsvCell(this.value, {this.forceQuote = false});

  final String value;
  final bool forceQuote;
}

class _HeaderIndex {
  _HeaderIndex(List<String> headers)
    : _indices = {
        for (var i = 0; i < headers.length; i++) _normalize(headers[i]): i,
      };

  final Map<String, int> _indices;

  String first(List<String> values, List<String> aliases) {
    for (final alias in aliases) {
      final index = _indices[_normalize(alias)];
      if (index == null || index >= values.length) continue;
      return values[index];
    }
    return '';
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
