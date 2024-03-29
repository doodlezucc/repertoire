import 'package:http/http.dart' as http;

Future<String> download(dynamic uri) async {
  var response = await http.get(Uri.parse(uri));
  return response.body;
}

class GoScraper {
  static Future<dynamic> getFirstResult(String query, String site) async {
    query = query.replaceAll(RegExp(r'\(([^)]+)\)'), '').trim();
    try {
      var uri = Uri.https('www.google.com', '/search', {
        'q': '$query site:$site',
      });
      print(uri);
      var response = await http.get(uri);
      print(response.statusCode);
      var s = response.body;
      s = s.substring(s.indexOf('<a href="/url') + 16);
      if (s.startsWith('https://www.go')) {
        // accidentally got google preferences url
        s = s.substring(s.indexOf('<a href="/url') + 16);
      }
      s = s.substring(0, s.indexOf('&amp;'));
      return s;
    } catch (e) {
      throw 'Search failed!';
    }
  }
}
