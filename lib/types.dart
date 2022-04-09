// To parse this JSON data, do
//
//     final stream = streamFromJson(jsonString);

import 'dart:convert';

Stream streamFromJson(String str) => Stream.fromJson(json.decode(str));

String streamToJson(Stream data) => json.encode(data.toJson());

class Stream {
  Stream({
    required this.source,
    required this.sourceBk,
    required this.track,
    required this.advertising,
    required this.linkiframe,
  });

  List<Source> source;
  List<Source> sourceBk;
  StreamTrack track;
  List<dynamic> advertising;
  String linkiframe;

  factory Stream.fromJson(Map<String, dynamic> json) => Stream(
    source: List<Source>.from(json["source"].map((x) => Source.fromJson(x))),
    sourceBk: List<Source>.from(json["source_bk"].map((x) => Source.fromJson(x))),
    track: StreamTrack.fromJson(json["track"]),
    advertising: List<dynamic>.from(json["advertising"].map((x) => x)),
    linkiframe: json["linkiframe"],
  );

  Map<String, dynamic> toJson() => {
    "source": List<dynamic>.from(source.map((x) => x.toJson())),
    "source_bk": List<dynamic>.from(sourceBk.map((x) => x.toJson())),
    "track": track.toJson(),
    "advertising": List<dynamic>.from(advertising.map((x) => x)),
    "linkiframe": linkiframe,
  };
}

class Source {
  Source({
    required this.file,
    required this.label,
    required this.type,
  });

  String file;
  String label;
  String type;

  factory Source.fromJson(Map<String, dynamic> json) => Source(
    file: json["file"],
    label: json["label"],
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "file": file,
    "label": label,
    "type": type,
  };
}

class StreamTrack {
  StreamTrack({
    required this.tracks,
  });

  List<TrackElement> tracks;

  factory StreamTrack.fromJson(Map<String, dynamic> json) => StreamTrack(
    tracks: List<TrackElement>.from(json["tracks"].map((x) => TrackElement.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "tracks": List<dynamic>.from(tracks.map((x) => x.toJson())),
  };
}

class TrackElement {
  TrackElement({
    required this.file,
    required this.kind,
  });

  String file;
  String kind;

  factory TrackElement.fromJson(Map<String, dynamic> json) => TrackElement(
    file: json["file"],
    kind: json["kind"],
  );

  Map<String, dynamic> toJson() => {
    "file": file,
    "kind": kind,
  };
}
