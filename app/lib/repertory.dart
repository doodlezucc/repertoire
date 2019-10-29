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
  List<Area> areas;

  Structure({this.areas = const []});
  Structure.basic() {
    areas = [];
  }

  Structure.fromJson(Map<String, dynamic> json)
      : areas = List.from(json["areas"]).map((j) => Area.fromJson(j)).toList();

  Map<String, dynamic> toJson() =>
      {"areas": areas.map((a) => a.toJson()).toList(growable: false)};
}

mixin Timed {
  int offset;

  Map<String, dynamic> timedToJson([Map<String, dynamic> append]) =>
      {"offset": offset}..addAll(append ?? {});

  void timedFromJson(Map<String, dynamic> json) {
    offset = json["offset"] ?? 0;
  }
}

class Voice {
  final String type;
  final IconData icon;

  const Voice(this.type, this.icon);

  static const Voice CHORDS = Voice("Chords", Icons.more_vert);
}

abstract class Segment {
  List<Timed> getTimed();
  Voice getVoice();

  Map<String, dynamic> toJson();

  bool hasData() => getTimed().length > 0;
}

class TimedChord extends Chord with Timed {
  TimedChord.fromChord(Chord chord, [int offset])
      : super(chord.root, chord.type) {
    this.offset = offset ?? 5;
  }

  TimedChord(ClampedPitch root, ChordType type, [int offset])
      : super(root, type) {
    this.offset = offset ?? 5;
  }

  void setChord(Chord chord) {
    root = chord.root;
    type = chord.type;
  }

  TimedChord.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    timedFromJson(json);
  }

  Map<String, dynamic> toJson() => timedToJson(super.toJson());
}

class ChordsSegment extends Segment {
  List<TimedChord> chords = [];

  ChordsSegment({this.chords});

  @override
  List<Timed> getTimed() {
    return chords;
  }

  @override
  Voice getVoice() {
    return Voice.CHORDS;
  }

  @override
  Map<String, dynamic> toJson() =>
      {"chords": chords.map((tc) => tc.toJson()).toList(growable: false)};
}

class TimedLyric with Timed {
  String text;

  TimedLyric(String text, [int offset]) {
    this.text = text;
    this.offset = offset ?? 0;
  }

  TimedLyric.fromJson(Map<String, dynamic> json) : text = json["text"] {
    timedFromJson(json);
  }

  Map<String, dynamic> toJson() => timedToJson({
        "text": text,
      });
}

class LyricsSegment extends Segment {
  List<TimedLyric> lyrics = [];

  LyricsSegment({this.lyrics});

  @override
  List<Timed> getTimed() {
    return lyrics;
  }

  @override
  Voice getVoice() {
    return Voice.CHORDS;
  }

  @override
  Map<String, dynamic> toJson() =>
      {"lyrics": lyrics.map((tl) => tl.toJson()).toList()};
}

class Area {
  ChordsSegment chords;
  LyricsSegment lyrics;

  Area(this.chords, this.lyrics);

  Area.fromJson(Map<String, dynamic> json)
      : chords = ChordsSegment(
            chords: List.from(json["chords"] ?? [])
                .map((jc) => TimedChord.fromJson(jc))
                .toList()),
        lyrics = LyricsSegment(
            lyrics: List.from(json["lyrics"] ?? [])
                .map((jl) => TimedLyric.fromJson(jl))
                .toList());

  Map<String, dynamic> toJson() => (chords.hasData() ? chords.toJson() : {})
    ..addAll(lyrics.hasData() ? lyrics.toJson() : {});
}

class AreaWidget extends StatelessWidget {
  final Area area;

  const AreaWidget({Key key, @required this.area}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
          // children: area.chords.chords.map((tc) => TimedChordField(

          // ))
          ),
    );
  }
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
