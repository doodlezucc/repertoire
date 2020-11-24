import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
          await File(
                  join((await getExternalStorageDirectory()).path, 'log.txt'))
              .writeAsString(html);
          print('Written to file!');
          print(e);
        }
      }
    } catch (e) {
      return WebError('Can\'t download site!');
    }
    return WebError('Lyrics extraction failed!');
  }

  static String extractFromString(String s) {
    var parsedLyricsStart = s.indexOf('s="ly');
    if (parsedLyricsStart < 0) {
      // JSON not parsed :shocked:
      print('Parsing JSON');
      s = s.substring(s.indexOf('JSON.parse') + 12);
      s = s.substring(s.indexOf('JSON.parse') + 12);
      s = s.substring(0, s.indexOf("');"));

      s = s
          .replaceAll('\\"', '"')
          .replaceAll("\\'", "'")
          .replaceAll('\\\\', '\\');

      var j = json.decode(s);
      var lyricsJson =
          j['songPage']['lyricsData']['body']['children'][0]['children'];

      var lyrics = gJson(lyricsJson);
      return lyrics.join();
    } else {
      // JSON is already parsed
      s = s.substring(parsedLyricsStart);
      s = s.substring(s.indexOf('<p>') + 3);
      s = s.substring(0, s.indexOf('</p>'));

      s = s.replaceAll(RegExp(r'<[\S\s]*?>'), '');
      return s.trim();
    }
  }

  static List<String> gJson(json) {
    if (json is String) {
      return json.isEmpty ? [] : [json];
    }

    if (json is List) {
      return json.map((e) => gJson(e)).reduce((list1, list2) => list1 + list2);
    }

    if (json['children'] != null) {
      return gJson(json['children']);
    }

    if (json['tag'] == 'br' || json['tag'] == 'inread-ad') {
      return ['\n'];
    }

    return [];
  }
}
