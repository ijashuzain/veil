import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';

class CommunityReportSheet extends StatefulWidget {
  const CommunityReportSheet({
    super.key,
    required this.title,
    required this.subjectLabel,
    required this.onSubmit,
  });

  final String title;
  final String subjectLabel;
  final Future<void> Function(String reason, String details) onSubmit;

  @override
  State<CommunityReportSheet> createState() => _CommunityReportSheetState();
}

class _CommunityReportSheetState extends State<CommunityReportSheet> {
  static const _reasons = [
    'Harassment or abuse',
    'Hate or discriminatory content',
    'Spam or scam',
    'Sexual or graphic content',
    'Spoilers without warning',
    'Other',
  ];

  final _detailsController = TextEditingController();
  var _selectedReason = _reasons.first;
  var _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VeilSheetScaffold(
      title: widget.title,
      trailing: IconButton(
        onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close_rounded),
        color: VeilColors.text2,
      ),
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Submitting...' : 'Submit report'),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        children: [
          Text(
            'Report ${widget.subjectLabel} for review by the Veil team.',
            style: const TextStyle(color: VeilColors.text2, height: 1.45),
          ),
          const SizedBox(height: 10),
          const Text(
            'Veil has zero tolerance for objectionable content or abusive users.',
            style: TextStyle(
              color: VeilColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const Text('Reason', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final reason in _reasons)
                ChoiceChip(
                  label: Text(reason),
                  selected: _selectedReason == reason,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _selectedReason = reason),
                  selectedColor: VeilColors.redSoft,
                  labelStyle: TextStyle(
                    color: _selectedReason == reason
                        ? Colors.white
                        : VeilColors.text2,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: _selectedReason == reason
                        ? VeilColors.red.withValues(alpha: .5)
                        : VeilColors.hairlineStrong,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Additional details',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _detailsController,
            minLines: 4,
            maxLines: 6,
            enabled: !_submitting,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add anything that will help us review this faster.',
              hintStyle: const TextStyle(color: VeilColors.text3),
              filled: true,
              fillColor: VeilColors.panelRaised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
                borderSide: const BorderSide(color: VeilColors.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
                borderSide: const BorderSide(color: VeilColors.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
                borderSide: const BorderSide(color: VeilColors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_selectedReason, _detailsController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
