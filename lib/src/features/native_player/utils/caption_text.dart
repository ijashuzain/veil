/// SRT/WebVTT inline formatting is not interpreted by ClosedCaption.
/// Strip recognized markup rather than treating dialogue as arbitrary HTML.
String plainCaptionText(String text) => text
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(
      RegExp(
        r'</?(?:i|b|u|font|ruby|rt|v|c|lang)(?:\.[\w-]+)*(?:\s+[^<>]*)?\s*/?>',
        caseSensitive: false,
      ),
      '',
    )
    .replaceAll(RegExp(r'<(?:\d{2}:)?\d{2}:\d{2}\.\d{3}>'), '')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');
