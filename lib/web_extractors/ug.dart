import 'package:http/http.dart' as http;
import 'package:repertories/repertory.dart';

class UGScraper {
  static Future<String> findLyrichords(SongData data) async {
    var uri = Uri.https("www.google.com", "/search", {
      "q": data.artist + " " + data.title + " site:tabs.ultimate-guitar.com",
    });
    print(uri);
    var response = await http.get(uri);
    var s = response.body;
    s = s.substring(s.indexOf("<a href=\"/url") + 16);
    s = s.substring(0, s.indexOf("&amp;"));

    return await scrapeLyrichords(s);
  }

  static Future<String> scrapeLyrichords(String url) async {
    print("Scraping $url");
    var response = await http.get(url);
    print('Response status: ${response.statusCode}');

    var s = response.body;
    s = s.substring(s.indexOf(";tab_view"));
    s = s.substring(s.indexOf("content") + 20);

    // find end of content
    for (var i = 0; i < s.length; i++) {
      if (s[i] == "\\") {
        i++; // skip next character as it's escaped
      } else if (s[i] == "&") {
        s = s.substring(0, i);
      }
    }

    s = s.replaceAll("\\r\\n", "\n");
    s = s.replaceAll(new RegExp(r"\[(.*?)ch\]"), "");
    s = s.replaceAll("[/tab]", "");
    s = s.replaceAll("&quot;", "\"");

    return s.trim();
  }
}
