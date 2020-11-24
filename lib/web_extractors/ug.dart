import 'package:html_unescape/html_unescape_small.dart';
import 'package:repertoire/web_extractors/go.dart';

class UGScraper {
  static Future<dynamic> findLyrichords(String title, String artist,
      {bool chords = true}) async {
    var resultUrl = await GoScraper.getFirstResult(
        '$title $artist' + (chords ? ' chords' : ''),
        'tabs.ultimate-guitar.com');

    if (resultUrl is WebError) return resultUrl;

    try {
      return extractFromString(await download(resultUrl));
    } catch (e) {
      return WebError('Can\'t extract correctly!');
    }
  }

  static String extractFromString(String s) {
    s = s.substring(s.indexOf(';tab_view'));
    s = s.substring(s.indexOf('content') + 20);

    // find end of content
    for (var i = 0; i < s.length; i++) {
      if (s[i] == '\\') {
        i++; // skip next character as it's escaped
      } else if (s[i] == '&' && s.substring(i + 1).startsWith('quot;')) {
        s = s.substring(0, i);
        break;
      }
    }

    s = s.replaceAll('\\r\\n', '\n');
    s = s.replaceAll(RegExp(r'\[\/?(ch|tab)\]'), '');
    s = s.replaceAll('[/tab]', '');

    s = HtmlUnescape().convert(s);
    s = s.replaceAll('&rsquo;', '\'');
    s = s.replaceAll('\\"', '"');

    return s.trim();
  }
}
