import 'package:flutter/material.dart';

import 'input.dart';
import 'music_theory.dart';

class Song {
  final Repertory repertory;
  String title;
  String artist;
  String get artistSort => artistSortCut(artist).toLowerCase();
  Set<Tag> tags = {};
  List<Segment> segments;

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

  Song({
    this.title = "Untitled",
    this.artist,
    this.tags = const {},
    this.segments,
    @required this.repertory,
  }) {
    if (segments == null) {
      segments = [Segment(ChordsElement(), LyricsElement())];
    }
  }

  Song.fromJson(
    Map<String, dynamic> json,
    List<Tag> tagList,
    Repertory repertory,
  ) : this(
          title: json["title"],
          artist: json["artist"],
          tags: List<int>.from(json["tags"])
              .map((index) => tagList[index])
              .toSet(),
          segments: List.from(json["segments"])
              .map((j) => Segment.fromJson(j))
              .toList(),
          repertory: repertory,
        );

  Map<String, dynamic> toJson(List<Tag> tagList) => {
        "title": title,
        "artist": artist,
        "tags": tags.map((t) => tagList.indexOf(t)).toList(growable: false),
        "segments": segments.map((s) => s.toJson()).toList(growable: false),
      };
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
  List<Chord> chords;

  ChordsElement({List<Chord> chords}) : this.chords = chords ?? [];

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
  List<Lyric> lyrics;

  LyricsElement({List<Lyric> lyrics}) : this.lyrics = lyrics ?? [];

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

class Segment {
  ChordsElement chords;
  LyricsElement lyrics;

  Segment(this.chords, this.lyrics);

  Segment.fromJson(Map<String, dynamic> json)
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

class SegmentWidget extends StatefulWidget {
  final Segment segment;

  const SegmentWidget({Key key, @required this.segment}) : super(key: key);

  @override
  _SegmentWidgetState createState() => _SegmentWidgetState();
}

class _SegmentWidgetState extends State<SegmentWidget> {
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
                  List.from(widget.segment.chords.chords.map((c) => ChordField(
                      value: c,
                      onChanged: (v) {
                        setState(() {
                          widget.segment.chords.chords.setAll(
                              widget.segment.chords.chords.indexOf(c), [v]);
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
                              widget.segment.chords.chords.add(result);
                            });
                          }
                        },
                      ),
                      widget.segment.lyrics.hasData()
                          ? Column(
                              children: widget.segment.lyrics.lyrics
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

  get isEmpty => songs.isEmpty;

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

    songs = List.from(json["songs"])
        .map((j) => Song.fromJson(j, tagList, this))
        .toSet();
  }

  Map<String, dynamic> toJson() {
    List<Tag> tagList = List<Tag>.from(getAllTags(), growable: false);

    return {
      "tags": tagList.map((t) => t.toJson()).toList(growable: false),
      "songs": songs.map((s) => s.toJson(tagList)).toList(growable: false)
    };
  }
}
