import 'package:veil/src/core/config/app_environment.dart';

class TmdbWatchProvider {
  const TmdbWatchProvider({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.displayPriority,
  });

  final int id;
  final String name;
  final String logoPath;
  final int displayPriority;

  String? get logoUrl => AppEnvironment.tmdbImageUrl('w154', logoPath);
}
