library ani_app.utils;

import 'dart:convert';
import 'dart:typed_data';
import "package:pointycastle/export.dart";

import 'package:html/dom.dart';
import 'package:html/parser.dart';

import 'constants.dart' as constants;

import 'dart:math';

extension Parser on String {
  Document parseString() {
    return parse(this);
  }

  WordArray parseHexString() {
    final latin1StrLength = length;

    // Convert
    List<int> words =
        List.generate(latin1StrLength >>> 2, (index) => 0, growable: false);
    for (var i = 0; i < latin1StrLength; i++) {
      words[i >>> 2] |= (codeUnitAt(i) & 0xff) << (24 - (i % 4) * 8);
    }

    return WordArray(words, latin1StrLength);
  }

  Uint8List decode() {
    return base64.decode(this);
  }
}

class WordArray {
  WordArray(this.words, this.sigBytes);

  final List<int> words;
  final int sigBytes;

  String stringify() {
    // Convert
    var hexChars = [];
    for (var i = 0; i < sigBytes; i++) {
      var bite = (words[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff;
      hexChars.add((bite >>> 4).toRadixString(16));
      hexChars.add((bite & 0x0f).toRadixString(16));
    }

    return hexChars.join('');
  }
}

String decodeKey(String id, String iv) {
  final decoded = utf8.decode(base64.decode(id));

  final value = decoded + "" + iv;

  final bytes =
      List<int>.generate(value.length, (index) => index, growable: false);

  return bytes
      .map((x) => value.codeUnitAt(x).toRadixString(16))
      .join("")
      .substring(0, 32)
      .parseHexString()
      .stringify();
}

class TokenData {
  String alias = "";
  String token = "";
  String expires = "";
  String op = "";

  TokenData(this.alias, this.token, this.expires,this.op);

  @override
  String toString() {
    // TODO: implement toString
    return "$token&$expires&$op";
  }
}

class KeyData {
  String iv = "";
  String key = "";
  String secretValue = "";
  TokenData token = TokenData("", "", "","");

  String decryptKey = "";

  KeyData(this.iv, this.key, this.secretValue, this.decryptKey, this.token);

  factory KeyData.scrapeKeys(Document html) {
    final token = html
        .querySelector('script[data-name="episode"]')
        ?.attributes["data-value"]!
        .decode();

    final secretValue = html
        .querySelector("body[class*='container-']")
        ?.attributes["class"]!
        .split("-")
        .removeLast()
        .parseHexString()
        .stringify();

    final alias = html.querySelector("#id")?.attributes["value"]!;

    final key = html
        .querySelector(constants.keyPath)
        ?.attributes["class"]!
        .split('-')
        .removeLast()
        .parseHexString()
        .stringify();

    final secondKey = html
        .querySelector(constants.secondKeyPath)
        ?.attributes["class"]!
        .split('-')
        .removeLast()
        .parseHexString()
        .stringify();

    final keyIV = html
        .querySelector("div[class*='container-']")
        ?.attributes["class"]!
        .split('-')
        .removeLast()
        .parseHexString()
        .stringify();

    if (secretValue != null &&
        key != null &&
        keyIV != null &&
        secondKey != null &&
        alias != null) {
      final decodedToken = decode(token!, secretValue, keyIV);

      final tokenParts = decodedToken
          .split("&")
          .where((x) => x.contains("token") || x.contains("expires") || x.contains("op"))
          .toList();
      // var key = decodeKey(alias, keyIV);
      return KeyData(keyIV, key, secretValue, secondKey,
          TokenData(alias, tokenParts.first,tokenParts[1], tokenParts.last));
    }

    return KeyData("", "", "", "", TokenData("", "", "",""));
  }
}

Uint8List pad(Uint8List src, int blockSize) {
  var pad = PKCS7Padding();
  pad.init(null);

  int padLength = blockSize - (src.length % blockSize);
  var out = Uint8List(src.length + padLength)..setAll(0, src);
  pad.addPadding(out, src.length);

  return out;
}

Uint8List createUint8ListFromString(String s) {
  var ret = Uint8List(s.length);
  for (var i = 0; i < s.length; i++) {
    ret[i] = s.codeUnitAt(i);
  }
  return ret;
}

Uint8List createUint8ListFromHexString(String hex) {
  var result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    var num = hex.substring(i, i + 2);
    var byte = int.parse(num, radix: 16);
    result[i ~/ 2] = byte;
  }
  return result;
}

String encodeToBase64(String plainText, String plainKey, String plainIv) {
  final key = createUint8ListFromHexString(plainKey);
  final iv = createUint8ListFromHexString(plainIv);

  final engine = AESEngine();

  final cbc = CBCBlockCipher(engine)
    ..init(true, ParametersWithIV(KeyParameter(key), iv));

  final paddedText =
      pad(createUint8ListFromString(plainText), engine.blockSize);

  final cipherText = Uint8List(paddedText.length);

  var offset = 0;
  while (offset < paddedText.length) {
    offset += cbc.processBlock(paddedText, offset, cipherText, offset);
  }

  return base64.encode(cipherText);
}

String decode(Uint8List cipherText, String plainKey, String plainIv) {
  final key = createUint8ListFromHexString(plainKey);
  final iv = createUint8ListFromHexString(plainIv);

  final engine = AESEngine();

  final cbc = CBCBlockCipher(engine)
    ..init(false, ParametersWithIV(KeyParameter(key), iv));

  final paddedText = Uint8List(cipherText.length);

  var offset = 0;
  while (offset < cipherText.length) {
    offset += cbc.processBlock(cipherText, offset, paddedText, offset);
  }

  final minByte = paddedText.reduce((value, element) {
    return min(value, element);
  });

  final cleanText = paddedText.where((x) {
    return !(x == minByte);
  }).toList();

  return utf8.decode(cleanText).replaceAll('\f', "");
}
