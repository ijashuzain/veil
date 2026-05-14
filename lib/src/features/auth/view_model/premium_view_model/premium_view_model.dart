import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/features/auth/repository/user_profile_repository.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';

part 'premium_view_model.g.dart';

@riverpod
Future<bool> currentUserIsPremium(Ref ref) async {
  final userId = ref.watch(authViewModelProvider).user?.id;
  if (userId == null || userId.isEmpty) return false;

  try {
    return await ref
        .read(userProfileRepositoryProvider)
        .isPremium(userId: userId);
  } catch (error, stackTrace) {
    log('Premium status lookup failed.', error: error, stackTrace: stackTrace);
    return false;
  }
}
