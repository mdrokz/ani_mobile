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

String encodeToBase64(String plainText,String plainKey,String plainIv) {

  final key = createUint8ListFromHexString(plainKey);
  final iv = createUint8ListFromHexString(plainIv);

  final engine = AESEngine();

  final cbc = CBCBlockCipher(engine)
    ..init(true, ParametersWithIV(KeyParameter(key), iv));

  final paddedText = pad(createUint8ListFromString(plainText),engine.blockSize);

  final cipherText = Uint8List(paddedText.length);

  var offset = 0;
  while (offset < paddedText.length) {
    offset += cbc.processBlock(paddedText, offset, cipherText, offset);
  }

  return base64.encode(cipherText);
}


String decode(Uint8List cipherText,String plainKey,String plainIv) {

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
    return min(value,element);
  });

  final cleanText = paddedText.where((x) {
    return !(x == minByte);
  }).toList();

  return utf8.decode(cleanText).replaceAll('\f',"");
}