import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/letterboxd/models/letterboxd_import_export.dart';
import 'package:veil/src/features/letterboxd/services/letterboxd_import_export_service.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';

void main() {
  final service = LetterboxdImportExportService();

  test('exports movie diary and watchlist rows as Letterboxd zip files', () {
    final export = service.buildExport([
      _entry(
        title: 'Black Panther: Wakanda Forever',
        tmdbId: 505642,
        imdbId: 'tt9114286',
        rating: 4.5,
        review: 'Loved, with tears',
        tags: const ['rewatch', 'marvel', 'phase four'],
        watchedOn: DateTime(2024, 2, 1),
      ),
      _entry(
        id: 'movie_693134',
        title: 'Dune: Part Two',
        tmdbId: 693134,
        imdbId: 'tt15239678',
        inWatchlist: true,
      ),
      _entry(
        id: 'tv_1399',
        mediaType: 'tv',
        title: 'Game of Thrones',
        tmdbId: 1399,
        watchedOn: DateTime(2024, 2, 2),
      ),
    ]);

    expect(export.unsupportedCount, 1);
    expect(export.activityCount, 1);
    expect(export.watchlistCount, 1);

    final archive = ZipDecoder().decodeBytes(export.bytes);
    final names = archive.files.map((file) => file.name).toList();
    expect(names, contains('veil-letterboxd-activity.csv'));
    expect(names, contains('veil-letterboxd-watchlist.csv'));
    expect(names, contains('veil-letterboxd-skipped.csv'));

    final activity = _textFile(archive, 'veil-letterboxd-activity.csv');
    expect(
      activity,
      startsWith(
        'Title,Year,LetterboxdURI,tmdbID,imdbID,Rating,WatchedDate,Rewatch,Tags,Review',
      ),
    );
    expect(
      activity,
      contains(
        '"Black Panther: Wakanda Forever",2022,,505642,tt9114286,4.5,2024-02-01,true,"marvel, phase four","Loved, with tears"',
      ),
    );

    final watchlist = _textFile(archive, 'veil-letterboxd-watchlist.csv');
    expect(watchlist, contains('"Dune: Part Two",2022,,693134,tt15239678'));
    expect(
      _textFile(archive, 'veil-letterboxd-skipped.csv'),
      contains('Game of Thrones'),
    );
  });

  test('parses Letterboxd diary CSV with quoted commas and new lines', () {
    const csv = '''
Date,Name,Year,Letterboxd URI,Rating,Rewatch,Tags,Review,tmdbID,imdbID
2024-02-01,"Black Panther: Wakanda Forever",2022,,4.5,Yes,"marvel, phase four","Great, layered
and bold",505642,tt9114286
''';

    final preview = service.parseImportFiles([
      LetterboxdImportFile(name: 'diary.csv', bytes: utf8.encode(csv)),
    ]);

    expect(preview.totalRows, 1);
    expect(preview.activityCount, 1);
    expect(preview.watchlistCount, 0);
    expect(preview.unsupportedCount, 0);

    final row = preview.rows.single;
    expect(row.source, LetterboxdImportSource.activity);
    expect(row.entry.title, 'Black Panther: Wakanda Forever');
    expect(row.entry.year, 2022);
    expect(row.entry.tmdbId, 505642);
    expect(row.entry.imdbId, 'tt9114286');
    expect(row.entry.rating, 4.5);
    expect(row.entry.watchedOn, DateTime(2024, 2, 1));
    expect(row.entry.review, 'Great, layered\nand bold');
    expect(row.entry.tags, ['rewatch', 'marvel', 'phase four']);
    expect(row.entry.inWatchlist, isFalse);
  });

  test(
    'parses Letterboxd export zip and keeps watchlist rows watchlist-only',
    () {
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'diary.csv',
            'Date,Name,Year,Rating,tmdbID\n2024-01-01,Heat,1995,5,949\n',
          ),
        )
        ..addFile(
          ArchiveFile.string(
            'watchlist.csv',
            'Date,Name,Year,tmdbID,imdbID\n2024-03-10,Dune: Part Two,2024,693134,tt15239678\n',
          ),
        );
      final bytes = ZipEncoder().encode(archive);

      final preview = service.parseImportFiles([
        LetterboxdImportFile(name: 'letterboxd.zip', bytes: bytes),
      ]);

      expect(preview.activityCount, 1);
      expect(preview.watchlistCount, 1);

      final watchlist = preview.rows.singleWhere(
        (row) => row.source == LetterboxdImportSource.watchlist,
      );
      expect(watchlist.entry.title, 'Dune: Part Two');
      expect(watchlist.entry.inWatchlist, isTrue);
      expect(watchlist.entry.rating, 0);
      expect(watchlist.entry.watchedOn, isNull);
    },
  );

  test('treats watched export rows as activity without rating or date', () {
    const csv = 'Name,Year,tmdbID\nHeat,1995,949\n';

    final preview = service.parseImportFiles([
      LetterboxdImportFile(name: 'watched.csv', bytes: utf8.encode(csv)),
    ]);

    expect(preview.activityCount, 1);
    expect(preview.watchlistCount, 0);
    expect(preview.rows.single.entry.inWatchlist, isFalse);
    expect(preview.rows.single.entry.watchedOn, isNotNull);
  });
}

String _textFile(Archive archive, String name) {
  final file = archive.files.singleWhere((candidate) => candidate.name == name);
  return utf8.decode(file.content as List<int>);
}

SocialEntry _entry({
  String id = 'movie_505642',
  String mediaType = 'movie',
  required String title,
  int tmdbId = 505642,
  String? imdbId,
  double rating = 0,
  String review = '',
  List<String> tags = const [],
  DateTime? watchedOn,
  bool inWatchlist = false,
}) {
  return SocialEntry(
    id: id,
    userId: 'local-user',
    tmdbId: tmdbId,
    imdbId: imdbId,
    mediaType: mediaType,
    title: title,
    year: 2022,
    type: mediaType == 'movie' ? 'Movie' : 'TV',
    rating: rating,
    review: review,
    tags: tags,
    watchedOn: watchedOn,
    inWatchlist: inWatchlist,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}
