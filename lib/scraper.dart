library ani_app.scraper;

import 'dart:convert';
import 'dart:io';

import 'constants.dart' as constants;
import 'utils.dart' as utils;
import 'types.dart';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

final httpClient = HttpClient();

Future<List<Map<String,String>>> searchAnime(String name) async {
  final req = await httpClient
      .getUrl(Uri.parse("${constants.baseUrl}/search.html?keyword=$name"));

  req.headers.set("User-Agent",constants.userAgent);

  final res = await req.close();

  final html = (await res.transform(utf8.decoder).join()).parseString();

  final animeList = html.querySelectorAll('a').where((x) {
    return x.attributes["href"]!.contains("/videos/");
  }).map((x) {
    final anime =  x.attributes["href"]!;
    final cover = x.querySelector('img')?.attributes["src"]!;
    return {
      anime: cover!
    };
  }).toList();

  return animeList;
}

Future<List<Map<String,String>>> getEpisodes(String animeId) async {

  final splitAnimeId = animeId.split('/');

  final animeTempId = "/videos/${(splitAnimeId[2] = (splitAnimeId[2].split('-')..removeLast()).join('-'))}";

  final req = await httpClient
      .getUrl(Uri.parse("${constants.baseUrl}/$animeId"));

  req.headers.set("User-Agent",constants.userAgent);

  final res = await req.close();

  final html = (await res.transform(utf8.decoder).join()).parseString();

  final episodeList = html.querySelectorAll('a').reversed.where((x) {
    return x.attributes["href"]!.contains(animeTempId);
  }).map((x) {
    final episode =  x.attributes["href"]!;
    final cover = x.querySelector('img')?.attributes["src"]!;
    return {
      episode: cover!
    };
  }).toList();

  return episodeList;
}

Future<String> getDpageLink(String episodeLink) async {

  final req = await httpClient
      .getUrl(Uri.parse("${constants.baseUrl}/$episodeLink"));

  req.headers.set("User-Agent",constants.userAgent);

  final res = await req.close();

  final html = (await res.transform(utf8.decoder).join()).parseString();

  final link = html.querySelector('iframe')?.attributes["src"]!;

  if(link != null) {
    return link;
  }

  return "";
}

Future<String> decryptLink(String downloadLink) async {

  final id = downloadLink.split('=')[1].split('&')[0];

  final encrypted = utils.encodeToBase64(id, constants.secretKey, constants.iv);

  final req = await httpClient
      .getUrl(Uri.parse("${constants.decryptionUrl}?id=$encrypted"));

  req.headers.set("User-Agent",constants.userAgent);
  req.headers.add("X-Requested-With", "XMLHttpRequest");
  
  final res = await req.close();

  final data = (await res.transform(utf8.decoder).join());

  final base64Data = data.split(":")[1].replaceAll("}","").replaceAll("\"","").replaceAll("\\","");

  final decrypted = base64.decode(base64Data);

  final decryptedData = streamFromJson(utils.decode(decrypted, constants.secretKey, constants.iv));

  return decryptedData.source.first.file;
}
