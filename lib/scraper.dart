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

  getEpisodes(animeList[0]);

  return animeList;
}

Future<List<String>> getEpisodes(String animeId) async {

  final splitAnimeId = animeId.split('/');

  final animeTempId = "/videos/${(splitAnimeId[2] = (splitAnimeId[2].split('-')..removeLast()).join('-'))}";

  final req = await httpClient
      .getUrl(Uri.parse("${constants.baseUrl}/$animeId"));

  final res = await req.close();

  final html = (await res.transform(utf8.decoder).join()).parseString();

  final episodeList = html.querySelectorAll('a').reversed.where((x) {
    return x.attributes["href"]!.contains(animeTempId);
  }).map((x) {
    return x.attributes["href"]!;
  }).toList();

  return episodeList;
}
