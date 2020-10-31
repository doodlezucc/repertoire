import 'package:repertoire/web_extractors/go.dart';

class GeniusScraper {
  static Future<dynamic> findLyrics(String title, String artist) async {
    var resultUrl =
        await GoScraper.getFirstResult('$title $artist', 'genius.com');

    if (resultUrl is WebError) return resultUrl;

    try {
      for (int i = 0; i < 3; i++) {
        var html = await download(resultUrl);
        try {
          return extractFromString(html);
        } catch (e) {
          print(e);
        }
      }
    } catch (e) {
      return WebError('Can\'t download site!');
    }
    return WebError('Lyrics extraction failed!');
  }

  static String extractFromString(String s) {
    s = s.substring(s.indexOf('s="ly'));
    s = s.substring(s.indexOf('<p>') + 3);
    s = s.substring(0, s.indexOf('</p>'));

    s = s.replaceAll(RegExp(r'<[\S\s]*?>'), '');

    return s.trim();
  }
}
