library ani_app.scraper;

import 'dart:convert';
import 'dart:io';

import 'constants.dart' as constants;

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

final httpClient = HttpClient();

Future<String> searchAnime(String name) async {

    final req = await httpClient.getUrl(Uri.parse("${constants.baseUrl}/search.html?keyword=$name"));

    final res = await req.close();

    final html = await res.transform(utf8.decoder).join();

    return html;
}