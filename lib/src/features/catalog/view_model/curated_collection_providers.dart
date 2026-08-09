import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/features/catalog/models/curated_collection.dart';
import 'package:veil/src/features/catalog/repository/curated_collection_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'curated_collection_providers.g.dart';

@riverpod
Future<List<CuratedCollection>> curatedCollections(Ref ref) {
  return ref.watch(curatedCollectionRepositoryProvider).collections();
}

@riverpod
Future<List<ContentItem>> curatedCollectionItems(Ref ref, String collectionId) {
  return ref.watch(curatedCollectionRepositoryProvider).items(collectionId);
}
