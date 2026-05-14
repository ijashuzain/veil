import 'package:veil/src/shared/models/content_item.dart';

class AlertItem {
  const AlertItem({
    required this.content,
    required this.tag,
    required this.title,
    required this.time,
    this.unread = false,
  });

  final ContentItem content;
  final String tag;
  final String title;
  final String time;
  final bool unread;

  AlertItem copyWith({
    ContentItem? content,
    String? tag,
    String? title,
    String? time,
    bool? unread,
  }) {
    return AlertItem(
      content: content ?? this.content,
      tag: tag ?? this.tag,
      title: title ?? this.title,
      time: time ?? this.time,
      unread: unread ?? this.unread,
    );
  }
}
