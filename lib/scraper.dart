library ani_app.scraper;

import 'dart:convert';
import 'dart:io';

import 'constants.dart' as constants;

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

final httpClient = HttpClient();

Future<List<String>> searchAnime(String name) async {
  final req = await httpClient
      .getUrl(Uri.parse("${constants.baseUrl}/search.html?keyword=$name"));

  final res = await req.close();

  final html = (await res.transform(utf8.decoder).join()).parseString();

  final animeList = html.querySelectorAll('a').where((x) {
    return x.attributes["href"]!.contains("/videos/");
  }).map((x) {
    return x.attributes["href"]!;
  }).toList();

  return animeList;
}
