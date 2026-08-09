class CuratedCollection {
  const CuratedCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
  });

  final String id;
  final String title;
  final String description;
  final List<String> tags;
}
