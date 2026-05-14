import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/letterboxd/models/letterboxd_import_export.dart';
import 'package:veil/src/features/letterboxd/services/letterboxd_file_service.dart';
import 'package:veil/src/features/letterboxd/services/letterboxd_import_export_service.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';

class LetterboxdImportExportSheet extends ConsumerStatefulWidget {
  const LetterboxdImportExportSheet({super.key});

  @override
  ConsumerState<LetterboxdImportExportSheet> createState() =>
      _LetterboxdImportExportSheetState();
}

class _LetterboxdImportExportSheetState
    extends ConsumerState<LetterboxdImportExportSheet> {
  final _service = const LetterboxdImportExportService();
  final _fileService = const LetterboxdFileService();

  LetterboxdImportPreview? _preview;
  String _message = '';
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialLibraryViewModelProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_vert_rounded, color: VeilColors.red),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Letterboxd',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ActionTile(
                icon: Icons.file_upload_rounded,
                title: 'Export ZIP',
                subtitle:
                    '${state.diary.length} watched, ${state.watchlist.length} watchlist',
                onTap: _busy ? null : () => _export(state.entries),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.file_download_rounded,
                title: 'Import CSV or ZIP',
                subtitle: 'Diary, ratings, reviews, tags, watchlist',
                onTap: _busy ? null : _pickImport,
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(color: VeilColors.red),
              ],
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  _message,
                  style: const TextStyle(
                    color: VeilColors.text2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (_preview != null) ...[
                const SizedBox(height: 16),
                _ImportPreviewPanel(
                  preview: _preview!,
                  onApply: _busy || _preview!.isEmpty ? null : _applyImport,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(List<SocialEntry> entries) async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final export = _service.buildExport(entries);
      await _fileService.saveExport(export);
      if (!mounted) return;
      setState(() {
        _message =
            'Exported ${export.activityCount} activity rows and ${export.watchlistCount} watchlist rows.'
            '${export.unsupportedCount == 0 ? '' : ' Skipped ${export.unsupportedCount} TV rows.'}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Export failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImport() async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final files = await _fileService.pickImportFiles();
      if (!mounted) return;
      if (files.isEmpty) {
        setState(() => _message = 'No file selected.');
        return;
      }
      final preview = _service.parseImportFiles(files);
      setState(() {
        _preview = preview;
        _message = preview.isEmpty
            ? 'No importable movie rows found.'
            : '${preview.totalRows} movie rows ready to import.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Import preview failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyImport() async {
    final preview = _preview;
    if (preview == null || preview.isEmpty) return;

    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final result = await ref
          .read(socialLibraryViewModelProvider.notifier)
          .importEntries(preview.entries);
      if (!mounted) return;
      setState(() {
        _message =
            'Imported ${result.applied} films: ${result.added} added, ${result.updated} updated.';
        if (result.tmdbLinked > 0 || result.tmdbUnresolved > 0) {
          _message =
              '$_message Linked ${result.tmdbLinked} with TMDB'
              '${result.tmdbUnresolved == 0 ? '.' : ', skipped ${result.tmdbUnresolved} unresolved.'}';
        }
        _preview = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Import failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VeilColors.panel,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: VeilColors.text1),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: VeilColors.text3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: VeilColors.text3),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportPreviewPanel extends StatelessWidget {
  const _ImportPreviewPanel({required this.preview, required this.onApply});

  final LetterboxdImportPreview preview;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PreviewChip(label: '${preview.activityCount} activity'),
                _PreviewChip(label: '${preview.watchlistCount} watchlist'),
                _PreviewChip(label: '${preview.unsupportedCount} skipped'),
              ],
            ),
            if (preview.warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final warning in preview.warnings)
                Text(
                  warning,
                  style: const TextStyle(color: VeilColors.text3, fontSize: 12),
                ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Apply import'),
                style: FilledButton.styleFrom(
                  backgroundColor: VeilColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      VeilTheme.controlRadius,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panelRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
