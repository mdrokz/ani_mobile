library ani_app.globals;

import 'package:html/dom.dart';
import 'package:html/parser.dart';


String baseUrl = "https://gogoplay4.com";

extension Parser on String {
  Document parseString() {
    return parse(this);
  }
}