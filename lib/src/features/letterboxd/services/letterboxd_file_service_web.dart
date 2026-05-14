// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:veil/src/features/letterboxd/models/letterboxd_import_export.dart';

class LetterboxdFileService {
  const LetterboxdFileService();

  Future<List<LetterboxdImportFile>> pickImportFiles() async {
    final input = html.FileUploadInputElement()
      ..accept = '.csv,.zip,text/csv,application/zip'
      ..multiple = true
      ..style.display = 'none';
    html.document.body?.append(input);

    final completer = Completer<List<html.File>?>();
    StreamSubscription<html.Event>? changeSub;
    StreamSubscription<html.Event>? cancelSub;

    void complete(List<html.File>? files) {
      if (completer.isCompleted) return;
      completer.complete(files);
    }

    changeSub = input.onChange.listen((_) {
      complete(input.files?.toList() ?? const []);
    });
    cancelSub = input.on['cancel'].listen((_) => complete(null));

    input.click();
    final files = await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => null,
    );

    await changeSub.cancel();
    await cancelSub.cancel();
    input.remove();

    if (files == null || files.isEmpty) return const [];

    final imported = <LetterboxdImportFile>[];
    for (final file in files) {
      imported.add(
        LetterboxdImportFile(name: file.name, bytes: await _readFile(file)),
      );
    }
    return imported;
  }

  Future<String?> saveExport(LetterboxdExportBundle export) async {
    final blob = html.Blob([export.bytes], 'application/zip');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = export.fileName
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    Future<void>.delayed(
      const Duration(seconds: 1),
      () => html.Url.revokeObjectUrl(url),
    );
    return null;
  }
}

Future<Uint8List> _readFile(html.File file) {
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();

  reader.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(reader.error ?? 'Could not read ${file.name}');
    }
  });
  reader.onLoadEnd.listen((_) {
    if (completer.isCompleted) return;
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(result.asUint8List());
    } else if (result is Uint8List) {
      completer.complete(result);
    } else if (result is List<int>) {
      completer.complete(Uint8List.fromList(result));
    } else {
      completer.completeError('Could not read ${file.name}');
    }
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}
