import 'package:http/http.dart' as http;

import '../repertory.dart';

class WebError implements Error {
  final String msg;

  WebError(this.msg);

  @override
  StackTrace get stackTrace => null;
  @override
  String toString() => msg;
}

class UGScraper {
  static Future<dynamic> findLyrichords(SongData data) async {
    try {
      var uri = Uri.https("www.google.com", "/search", {
        "q": data.artist + " " + data.title + " site:tabs.ultimate-guitar.com",
      });
      print(uri);
      var response = await http.get(uri);
      var s = response.body;
      s = s.substring(s.indexOf("<a href=\"/url") + 16);
      s = s.substring(0, s.indexOf("&amp;"));

      return await scrapeLyrichords(s);
    } catch (e) {
      return WebError("Can't connect to search engine!");
    }
  }

  static Future<dynamic> scrapeLyrichords(String ugUrl) async {
    try {
      print("Scraping $ugUrl");
      var response = await http.get(ugUrl);
      print('Response status: ${response.statusCode}');

      var s = response.body;
      s = s.substring(s.indexOf(";tab_view"));
      s = s.substring(s.indexOf("content") + 20);

      // find end of content
      for (var i = 0; i < s.length; i++) {
        if (s[i] == "\\") {
          i++; // skip next character as it's escaped
        } else if (s[i] == "&" && s.substring(i + 1).startsWith("quot;")) {
          s = s.substring(0, i);
          break;
        }
      }

      s = s.replaceAll("\\r\\n", "\n");
      s = s.replaceAll(new RegExp(r"\[(.*?)ch\]"), "");
      s = s.replaceAll("[/tab]", "");
      s = s.replaceAll("&quot;", "\"");
      s = s.replaceAll("\\", "");

      return s.trim();
    } catch (e) {
      return WebError("Can't extract correctly!");
    }
  }
}
