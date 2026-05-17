const veilRatingValues = <double>[.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5];

double normalizeVeilRating(double rating, {bool allowUnrated = false}) {
  if (!rating.isFinite) return allowUnrated ? 0 : .5;
  if (allowUnrated && rating <= 0) return 0;

  final clamped = rating.clamp(.5, 5).toDouble();
  return (clamped * 2).round() / 2;
}

String formatVeilRating(double rating) {
  final normalized = normalizeVeilRating(rating, allowUnrated: true);
  if (normalized == 0) return '';
  if (normalized == normalized.roundToDouble()) {
    return normalized.toInt().toString();
  }
  return normalized.toStringAsFixed(1);
}
