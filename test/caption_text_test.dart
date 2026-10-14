import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/native_player/utils/caption_text.dart';

void main() {
  test('removes SRT formatting and preserves dialogue line breaks', () {
    expect(
      plainCaptionText(
        '<i>and wake up in two years</i>\n<i>when I\'ll already have graduated.</i>',
      ),
      "and wake up in two years\nwhen I'll already have graduated.",
    );
    expect(
      plainCaptionText('<font color="#fff"><b>Hello</b></font><br/>World'),
      'Hello\nWorld',
    );
  });
  test('removes WebVTT voice, class and timestamp markup', () {
    expect(
      plainCaptionText('<v Peter><c.white>Hello</c> <00:01.500>there</v>'),
      'Hello there',
    );
  });
  test('preserves literal comparisons and decodes common entities once', () {
    expect(plainCaptionText('2 < 3 &amp; 5 > 4'), '2 < 3 & 5 > 4');
    expect(plainCaptionText('&lt;i&gt;literal&lt;/i&gt;'), '<i>literal</i>');
  });
}
