import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veil/app/services/supabase_services/supabase_service.dart';

part 'user_profile_repository.g.dart';

@riverpod
UserProfileRepository userProfileRepository(Ref ref) {
  return UserProfileRepository(client: SupabaseService.client);
}

class UserProfileRepository {
  UserProfileRepository({SupabaseClient? client}) : _client = client;

  static const _table = 'user_profiles';

  final SupabaseClient? _client;

  Future<bool> isPremium({required String userId}) async {
    final client = _client;
    if (client == null || userId.isEmpty) return false;

    final row = await client
        .from(_table)
        .select('is_premium')
        .eq('user_id', userId)
        .maybeSingle();
    return row?['is_premium'] == true;
  }
}
