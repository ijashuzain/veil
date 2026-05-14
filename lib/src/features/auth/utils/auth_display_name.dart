import 'package:supabase_flutter/supabase_flutter.dart';

String authDisplayName(User? user, {String fallback = 'Veil member'}) {
  final metadata = user?.userMetadata;
  for (final key in const ['display_name', 'full_name', 'name']) {
    final value = metadata?[key] as String?;
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }

  final email = user?.email;
  if (email != null && email.contains('@')) return email.split('@').first;

  return fallback;
}
