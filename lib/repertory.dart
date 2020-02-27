import 'package:flutter/material.dart';

import 'input.dart';
import 'music_theory.dart';

class Song {
  String title;
  String artist;
  String get artistSort => artistSortCut(artist).toLowerCase();
  Set<Tag> tags = {};
  Structure structure;

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
      this.structure}) {
    if (structure == null) {
      structure = Structure();
    }
  }

  Song.fromJson(Map<String, dynamic> json, List<Tag> tagList)
      : title = json["title"],
        artist = json["artist"],
        tags =
            List<int>.from(json["tags"]).map((index) => tagList[index]).toSet(),
        structure = Structure.fromJson(json["structure"]);

  Map<String, dynamic> toJson(List<Tag> tagList) => {
        "title": title,
        "artist": artist,
        "tags": tags.map((t) => tagList.indexOf(t)).toList(growable: false),
        "structure": structure.toJson()
      };
}

class Structure {
  List<Section> sections;

  Structure({this.sections = const []});
  Structure.basic() {
    sections = [];
  }

  Structure.fromJson(Map<String, dynamic> json)
      : sections = List.from(json["sections"])
            .map((j) => Section.fromJson(j))
            .toList();

  Map<String, dynamic> toJson() =>
      {"sections": sections.map((a) => a.toJson()).toList(growable: false)};
}

class Voice {
  final String type;
  final IconData icon;

  const Voice(this.type, this.icon);

  static const Voice CHORDS = Voice("Chords", Icons.more_vert);
}

abstract class Element {
  Voice getVoice();

  Map<String, dynamic> toJson();

  bool hasData();
}

class ChordsElement extends Element {
  List<Chord> chords = [];

  ChordsElement({this.chords});

  @override
  Voice getVoice() {
    return Voice.CHORDS;
  }

  @override
  Map<String, dynamic> toJson() =>
      {"chords": chords.map((tc) => tc.toJson()).toList(growable: false)};

  @override
  bool hasData() => chords != null && chords.length > 0;
}

class Lyric {
  String text;

  Lyric(String text) {
    this.text = text;
  }

  Lyric.fromJson(Map<String, dynamic> json) : text = json["text"];

  Map<String, dynamic> toJson() => {
        "text": text,
      };
}

class LyricsElement extends Element {
  List<Lyric> lyrics = [];

  LyricsElement({this.lyrics});

  @override
  Voice getVoice() {
    return Voice.CHORDS;
  }

  @override
  Map<String, dynamic> toJson() =>
      {"lyrics": lyrics.map((tl) => tl.toJson()).toList()};

  @override
  bool hasData() => lyrics != null && lyrics.length > 0;
}

class Section {
  ChordsElement chords;
  LyricsElement lyrics;

  Section(this.chords, this.lyrics);

  Section.fromJson(Map<String, dynamic> json)
      : chords = ChordsElement(
            chords: List.from(json["chords"] ?? [])
                .map((jc) => Chord.fromJson(jc))
                .toList()),
        lyrics = LyricsElement(
            lyrics: List.from(json["lyrics"] ?? [])
                .map((jl) => Lyric.fromJson(jl))
                .toList());

  Map<String, dynamic> toJson() => (chords.hasData() ? chords.toJson() : {})
    ..addAll(lyrics.hasData() ? lyrics.toJson() : {});
}

class SectionWidget extends StatefulWidget {
  final Section area;

  const SectionWidget({Key key, @required this.area}) : super(key: key);

  @override
  _SectionWidgetState createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<SectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.green[200], Colors.blue[200]],
              stops: [0, 1],
              begin: Alignment.bottomLeft)),
      child: Column(
        children: <Widget>[
          Wrap(
              children:
                  List.from(widget.area.chords.chords.map((c) => ChordField(
                      value: c,
                      onChanged: (v) {
                        setState(() {
                          widget.area.chords.chords.setAll(
                              widget.area.chords.chords.indexOf(c), [v]);
                        });
                      })))
                    ..addAll([
                      MaterialButton(
                        minWidth: 0,
                        child: Icon(Icons.add),
                        onPressed: () async {
                          dynamic result = await showInputChord(
                            context: context,
                          );
                          if (result != null) {
                            setState(() {
                              widget.area.chords.chords.add(result);
                            });
                          }
                        },
                      ),
                      widget.area.lyrics.hasData()
                          ? Column(
                              children: widget.area.lyrics.lyrics
                                  .map((l) => LyricWidget(lyric: l))
                                  .toList())
                          : Container()
                    ])),
        ],
      ),
    );
  }
}

class LyricWidget extends StatefulWidget {
  final Lyric lyric;

  const LyricWidget({Key key, @required this.lyric}) : super(key: key);

  @override
  _LyricWidgetState createState() => _LyricWidgetState();
}

class _LyricWidgetState extends State<LyricWidget> {
  TextEditingController _ctrl;

  @override
  void initState() {
    _ctrl = TextEditingController(text: widget.lyric.text);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onSubmitted: (s) {
        FocusScope.of(context).focusInDirection(TraversalDirection.down);
      },
      maxLines: null,
      controller: _ctrl,
      onChanged: (s) {
        widget.lyric.text = s;
      },
      style: TextStyle(fontFamily: "RobotoMono"),
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
