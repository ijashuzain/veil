import 'package:veil/src/features/letterboxd/models/letterboxd_import_export.dart';

class LetterboxdFileService {
  const LetterboxdFileService();

  Future<List<LetterboxdImportFile>> pickImportFiles() {
    throw UnsupportedError(_nativeMessage);
  }

  Future<String?> saveExport(LetterboxdExportBundle export) {
    throw UnsupportedError(_nativeMessage);
  }
}

const _nativeMessage =
    'Letterboxd file import/export is available in the web app. Native apps need a full store build before new file-access plugins can run.';
