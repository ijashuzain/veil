Future<bool> openExternalPlayer(String url) async {
  return openExternalPlayerCandidates([Uri.parse(url)]);
}

Future<bool> openExternalPlayerCandidates(List<Uri> urls) async {
  return false;
}

Future<bool> openExternalPlayerDirect(Uri url) async {
  return false;
}
