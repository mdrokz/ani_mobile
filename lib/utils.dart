library ani_app.utils;

import 'dart:convert';
import 'dart:typed_data';
import "package:pointycastle/export.dart";

import 'package:html/dom.dart';
import 'package:html/parser.dart';

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

    final cleanedWords = words.where((element) {
      return !(element == 0);
    }).toList();

    return WordArray(cleanedWords, latin1StrLength);
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

class KeyData {
  String iv = "";
  String key = "";
  String secretValue = "";
  String decryptKey = "";

  KeyData(this.iv, this.key, this.secretValue, this.decryptKey);

  factory KeyData.scrapeKeys(Document html) {
    var secretValue = html
        .querySelector('script[data-name="episode"]')
        ?.attributes["data-value"];

    var keyIV = html
        .querySelector("div[class*='container-']")
        ?.attributes["class"]!
        .split('-')
        .removeLast()
        .parseHexString()
        .stringify();
    var secondKeyId = html
        .querySelector("div[class*='videocontent-']")
        ?.attributes['class']!
        .split('-')
        .removeLast()
        .parseHexString()
        .stringify();
    var keyId = html
        .querySelector("body[class^='container-']")
        ?.attributes['class']!
        .split('-')
        .removeLast()
        .parseHexString()
        .stringify();

    if (secretValue != null &&
        keyIV != null &&
        secondKeyId != null &&
        keyId != null) {
      return KeyData(keyIV, keyId, secretValue, secondKeyId);
    }

    return KeyData("", "", "", "");
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
