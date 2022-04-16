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

Future<Map<String,String>> extractKeys(String downloadLink) async {

  final req = await httpClient
      .getUrl(Uri.parse(downloadLink));
  req.headers.set("User-Agent",constants.userAgent);

  final res = await req.close();

  final html = (await res.transform(utf8.decoder).join()).parseString();

  final keyData = utils.KeyData.scrapeKeys(html);

  final decoded = base64.decode(keyData.secretValue);

  final secretData = utils.decode(decoded, keyData.key, keyData.iv);

  final alias = secretData.substring(0,secretData.indexOf("&"));

  final id = utils.encodeToBase64(alias, keyData.key, keyData.iv);

  return {
    "alias": alias,
    "id": id,
    "key": keyData.decryptKey,
    "iv": keyData.iv
  };

}

Future<String> decryptLink(String alias,String id,String key,String iv) async {

  final req = await httpClient
      .getUrl(Uri.parse("${constants.decryptionUrl}?id=$id&alias=$alias"));

  req.headers.set("User-Agent",constants.userAgent);
  req.headers.add("X-Requested-With", "XMLHttpRequest");
  
  final res = await req.close();

  final data = (await res.transform(utf8.decoder).join());

  final base64Data = data.split(":")[1].replaceAll("}","").replaceAll("\"","").replaceAll("\\","");

  final decrypted = base64.decode(base64Data);

  final decryptedData = streamFromJson(utils.decode(decrypted, key, iv));

  return decryptedData.source.first.file;
}
