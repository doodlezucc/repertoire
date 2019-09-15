import 'package:flutter/material.dart';

import 'music_theory.dart';
import 'scores.dart';

class Song {
  String title;
  String artist;
  String get artistSort => artistSortCut(artist).toLowerCase();
  Set<Tag> tags = {};
  Structure structure;
  List<ScoreProvider> scoreProviders = [];

  String get description {
    String t = title.isEmpty ? "Untitled Song" : "\"$title\"";
    if (artist.isEmpty) {
      return t;
    }
    return "$t by $artist";
  }

  static String artistSortCut(String artist) =>
      artist.toLowerCase().startsWith("the") && artist.length > 7
          ? artist.substring(4)
          : artist;

  bool hasData() {
    return title.length > 0 || artist.length > 0 || tags.length > 0;
  }

  Song(
      {this.title = "Untitled",
      this.artist,
      this.tags = const {},
      this.structure,
      this.scoreProviders = const []}) {
    if (structure == null) {
      structure = Structure();
    }
  }

  Song.fromJson(Map<String, dynamic> json, List<Tag> tagList)
      : title = json["title"],
        artist = json["artist"],
        tags =
            List<int>.from(json["tags"]).map((index) => tagList[index]).toSet(),
        structure = Structure.fromJson(json["structure"]),
        scoreProviders = List.from(json["providers"])
            .map((jp) => ScoreProvider.fromJson(jp))
            .toList();

  Map<String, dynamic> toJson(List<Tag> tagList) => {
        "title": title,
        "artist": artist,
        "tags": tags.map((t) => tagList.indexOf(t)).toList(growable: false),
        "structure": structure.toJson(),
        "providers":
            scoreProviders.map((sp) => sp.toJson()).toList(growable: false)
      };
}

class Structure {
  List<Segment> segments;

  Structure({this.segments = const []});
  Structure.basic() {
    segments = [Segment(name: "Main", keyScale: KeyScale.cMajor())];
  }

  Structure.fromJson(Map<String, dynamic> json)
      : segments = List.from(json["segments"])
            .map((j) => Segment.fromJson(j))
            .toList();

  Map<String, dynamic> toJson() =>
      {"segments": segments.map((s) => s.toJson()).toList(growable: false)};
}

class Segment {
  String name;
  List<Chord> chords;
  KeyScale keyScale;
  String lyrics;

  Segment(
      {@required this.name,
      @required this.keyScale,
      this.chords = const [],
      this.lyrics = ""});

  Segment.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        chords =
            List.from(json["chords"]).map((jc) => Chord.fromJson(jc)).toList(),
        keyScale = KeyScale.fromJson(json["key"]),
        lyrics = json["lyrics"];

  Map<String, dynamic> toJson() => {
        "name": name,
        "chords": chords.map((c) => c.toJson()).toList(growable: false),
        "key": keyScale.toJson(),
        "lyrics": lyrics
      };
}

class Tag {
  String name;
  Color color;

  Tag({@required this.name, this.color = Colors.blueGrey});

  bool operator ==(other) => other is Tag && name == other.name;
  int get hashCode => name.hashCode;

  Tag.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        color = Color(json["color"]);

  Map<String, dynamic> toJson() => {"name": name, "color": color.value};
}

class Repertory {
  Set<Song> songs = {};

  Repertory();

  Set<String> getAllArtists() => songs.map((s) => s.artist).toSet();

  Set<Tag> getAllTags() {
    Set<Tag> out = {};
    songs.forEach((song) => out.addAll(song.tags));
    return out;
  }

  Repertory.fromJson(Map<String, dynamic> json) {
    List<Tag> tagList = List.from(json["tags"])
        .map((jtag) => Tag.fromJson(jtag))
        .toList(growable: false);

    songs =
        List.from(json["songs"]).map((j) => Song.fromJson(j, tagList)).toSet();
  }

  Map<String, dynamic> toJson() {
    List<Tag> tagList = List<Tag>.from(getAllTags(), growable: false);

    return {
      "tags": tagList.map((t) => t.toJson()).toList(growable: false),
      "songs": songs.map((s) => s.toJson(tagList)).toList(growable: false)
    };
  }
}
