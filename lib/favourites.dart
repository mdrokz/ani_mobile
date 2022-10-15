// To parse this JSON data, do
//
//     final favourite = favouriteFromJson(jsonString);

import 'dart:convert';

Map<String,Favourite> favouriteFromJson(String str) => Map<String,Favourite>.from(json.decode(str).map((x) => Favourite.fromJson(x)));

String favouriteToJson(Map<String,Favourite> data) => json.encode(data);

class Favourite {
  Favourite({
    required this.title,
    required this.episodes,
  });

  final String title;
  final List<Episode> episodes;

  factory Favourite.fromJson(Map<String, dynamic> json) => Favourite(
    title: json["title"],
    episodes: List<Episode>.from(json["episodes"].map((x) => Episode.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "episodes": List<dynamic>.from(episodes.map((x) => x.toJson())),
  };
}

class Episode {
  Episode({
    required this.title,
  });

  final String title;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    title: json["title"],
  );

  Map<String, dynamic> toJson() => {
    "title": title,
  };
}
