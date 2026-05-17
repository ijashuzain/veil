import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/detail/widgets/detail_review_sheet.dart';
import 'package:veil/src/shared/components/ratings_display.dart';
import 'package:veil/src/shared/models/content_item.dart';

void main() {
  testWidgets('star display delegates fractional rendering to rating package', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VeilStarRating(rating: 3.5))),
    );

    final indicator = tester.widget<RatingBarIndicator>(
      find.byType(RatingBarIndicator),
    );

    expect(indicator.rating, 3.5);
    expect(indicator.itemCount, 5);
  });

  testWidgets('detail rating selector enables package half-star mode', (
    tester,
  ) async {
    var selected = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DetailStarRatingSelector(
            rating: selected,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    final ratingBar = tester.widget<RatingBar>(find.byType(RatingBar));

    expect(ratingBar.allowHalfRating, isTrue);
    expect(ratingBar.minRating, .5);
  });

  testWidgets('visible star halves map to half and full ratings', (
    tester,
  ) async {
    var selected = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DetailStarRatingSelector(
              rating: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    final fourthStar = tester.getRect(find.byIcon(Icons.star_rounded).at(3));
    await tester.tapAt(fourthStar.centerLeft + const Offset(1, 0));
    expect(selected, 3.5);

    await tester.tapAt(fourthStar.centerRight - const Offset(1, 0));
    expect(selected, 4);
  });

  testWidgets('review sheet saves a half-star rating', (tester) async {
    double? savedRating;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DetailReviewSheet(
            item: _item,
            initialRating: 0,
            initialWatchTag: 'first-time',
            onSave: ({required rating, required review, required tags}) async {
              savedRating = rating;
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Add review...'),
      'Ok',
    );
    final firstStar = tester.getRect(find.byIcon(Icons.star_rounded).first);
    await tester.tapAt(firstStar.centerLeft + const Offset(1, 0));
    await tester.pump();

    final save = tester.widget<TextButton>(
      find.byKey(const ValueKey('detail-review-save')),
    );
    expect(save.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('detail-review-save')));
    await tester.pump();

    expect(savedRating, .5);
  });
}

const _item = ContentItem(
  id: 'movie-1',
  remoteId: 1,
  mediaType: 'movie',
  title: 'Heat',
  subtitle: 'Movie',
  year: 1995,
  genre: 'Crime',
  type: 'Movie',
  rating: 8.3,
  palette: [Colors.black, Colors.red],
  glyph: Icons.movie_rounded,
  description: 'A crime film.',
);
