import 'package:repertoire/web_extractors/go.dart';

class GeniusScraper {
  static Future<dynamic> findLyrics(String title, String artist) async {
    var resultUrl =
        await GoScraper.getFirstResult('$title $artist', 'genius.com');

    if (resultUrl is WebError) return resultUrl;

    try {
      return extractFromString(await download(resultUrl));
    } catch (e) {
      return WebError('Can\'t extract correctly!');
    }
  }

  static String extractFromString(String s) {
    s = s.substring(s.indexOf('s="ly'));
    s = s.substring(s.indexOf('<p>') + 3);
    s = s.substring(0, s.indexOf('</p>'));

    //s = s.replaceAll('\n', '');

    //s = s.split('<br>').map((line) => line.trim()).join('\n');

    s = s.replaceAll(RegExp(r'<[\S\s]*?>'), '');

    return s.trim();
  }
}
