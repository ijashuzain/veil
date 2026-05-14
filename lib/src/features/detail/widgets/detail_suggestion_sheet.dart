import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/user_profile_summary.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/models/content_item.dart';

typedef DetailFollowersLoader = Future<List<UserProfileSummary>> Function();
typedef DetailSuggestSubmit = Future<void> Function(List<String> recipientIds);

class DetailSuggestionSheet extends StatefulWidget {
  const DetailSuggestionSheet({
    super.key,
    required this.item,
    required this.currentUserId,
    required this.loadFollowers,
    required this.onSuggest,
  });

  final ContentItem item;
  final String currentUserId;
  final DetailFollowersLoader loadFollowers;
  final DetailSuggestSubmit onSuggest;

  @override
  State<DetailSuggestionSheet> createState() => _DetailSuggestionSheetState();
}

class _DetailSuggestionSheetState extends State<DetailSuggestionSheet> {
  var _followers = <UserProfileSummary>[];
  final _selected = <String>{};
  var _loading = true;
  var _sending = false;
  var _error = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selected.isNotEmpty && !_sending;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: VeilColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: VeilColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VeilColors.hairlineStrong,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  PosterArt(
                    item: widget.item,
                    width: 46,
                    height: 66,
                    radius: 6,
                    showTitle: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suggest',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VeilColors.text3,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(color: VeilColors.red),
                )
              else if (_followers.isEmpty)
                const _SuggestionMessage(
                  title: 'No followers yet',
                  message: 'Followers will appear here when they follow you.',
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .42,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _followers.length,
                    itemBuilder: (context, index) {
                      final follower = _followers[index];
                      final selected = _selected.contains(follower.userId);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (_) => _toggle(follower.userId),
                        activeColor: VeilColors.red,
                        checkColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          follower.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          _displayName(follower.userId),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VeilColors.text3,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _error,
                  style: const TextStyle(color: VeilColors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: VeilColors.red,
                    disabledBackgroundColor: VeilColors.redDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Suggest',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    try {
      final followers = await widget.loadFollowers();
      if (!mounted) return;
      setState(() {
        _followers = followers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _toggle(String userId) {
    setState(() {
      if (!_selected.add(userId)) {
        _selected.remove(userId);
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _error = '';
    });
    try {
      await widget.onSuggest(_selected.toList());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _sending = false;
      });
    }
  }
}

class _SuggestionMessage extends StatelessWidget {
  const _SuggestionMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: const TextStyle(color: VeilColors.text3, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _displayName(String userId) {
  final count = userId.length < 8 ? userId.length : 8;
  return '@${userId.substring(0, count)}';
}
