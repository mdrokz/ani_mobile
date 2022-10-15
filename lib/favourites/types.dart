// To parse this JSON data, do
//
//     final favourite = favouriteFromJson(jsonString);

import 'dart:convert';

Map<String,Favourite> favouriteFromJson(String str) {
  Map<String,dynamic> o = json.decode(str);

  Map<String,Favourite> y = {};

  for(final key in o.keys) {
    y[key] = Favourite.fromJson(o[key]);
  }

  return y;
}

String favouriteToJson(Map<String,Favourite> data) => json.encode(data);

class Favourite {
  Favourite({
    required this.title,
    required this.cover,
    required this.episodes,
  });

  final String title;
  final String cover;
  List<Episode?> episodes;

  factory Favourite.fromJson(Map<String, dynamic> json) => Favourite(
    title: json["title"],
    cover: json["cover"],
    episodes: List<Episode?>.from(json["episodes"].map((x) => x != null ? Episode.fromJson(x) : null)),
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "cover": cover,
    "episodes": List<dynamic>.from(episodes.map((x) => x?.toJson())),
  };
}

class Episode {
  Episode({
    required this.title,
    required this.cover
  });

  final String title;
  final String cover;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    title: json["title"],
    cover: json["cover"]
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "cover": cover
  };
}
