import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/detail/widgets/detail_review_sheet.dart';
import 'package:veil/src/shared/components/ratings_display.dart';

void main() {
  testWidgets('star display renders half-filled stars for half ratings', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VeilStarRating(rating: 3.5))),
    );

    final goldStars = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          widget.icon == Icons.star_rounded &&
          widget.color == VeilColors.gold,
    );
    final halfFill = tester.widget<Align>(
      find.byKey(const ValueKey('veil-star-fill-4')),
    );

    expect(goldStars, findsNWidgets(4));
    expect(halfFill.widthFactor, .5);
  });

  testWidgets('detail rating selector emits half-star values', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('detail-star-0.5')));
    expect(selected, .5);

    await tester.tap(find.byKey(const ValueKey('detail-star-3.5')));
    expect(selected, 3.5);
  });
}
