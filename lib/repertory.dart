import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class Song {
  final Repertory repertory;
  SongData _data;
  SongData get data => _data;
  File _file;
  File get file => _file;
  final int creationTimestamp;

  void setData(SongData newData, {bool isCreation = false}) {
    if (isCreation) {
      _file = File(getFilePath(newData, repertory));
      repertory.songs.add(this);
    } else if (_data.description != newData.description) {
      _file = _file.renameSync(getFilePath(newData, repertory));
      print("!Renamed file!");
    }
    _data = newData;
    save();
  }

  void save() {
    file.writeAsStringSync("$creationTimestamp\n" + data.saveToString());
    print("Saved " + data.description);
  }

  static String getFilePath(SongData data, Repertory repertory) =>
      join(repertory.directory.path, data.description.replaceAll("/", "-")) +
      ".txt";

  void remove() {
    file.delete();
    repertory.songs.remove(this);
  }

  Song(SongData data, this.repertory, this.creationTimestamp)
      : _data = data,
        _file = File(getFilePath(data, repertory));
}

class SongData {
  String title;
  String artist;
  String get artistSort => artistSortCut(artist).toLowerCase();
  Set<String> tags = {};
  String lyrichords;
  int transpose = 0;
  List<String> recordings;

  String get description {
    String t = title.isEmpty ? "Untitled" : title;
    if (artist.isEmpty) {
      return t;
    }
    return "$t by $artist";
  }

  bool matches(SongData other) {
    return title == other.title &&
        artist == other.artist &&
        setEquals(tags, other.tags) &&
        lyrichords == other.lyrichords &&
        transpose == other.transpose &&
        listEquals(recordings, other.recordings);
  }

  static String artistSortCut(String artist) =>
      artist.toLowerCase().startsWith("the") && artist.length > 7
          ? artist.substring(4)
          : artist;

  bool hasData() {
    return title.length > 0 || artist.length > 0 || tags.length > 0;
  }

  String saveToString() {
    return [
      title,
      artist,
      tags.map((e) => e.replaceAll(",", "\\,")).join(","),
      ['$transpose', ...recordings].join(','),
      "",
      lyrichords,
    ].join("\n");
  }

  static SongData parse(String s) {
    var lines = s.split("\n");
    final title = lines[0];
    final artist = lines[1];
    var line = lines[2];
    final tags = line.length > 0
        ? line.split(",").map((e) => e.replaceAll("\\,", ",")).toSet()
        : Set<String>();

    var divider = lines.indexWhere((line) => line.isEmpty, 3);
    final meta = divider >= 4 ? lines[3].split(',') : null;
    final transpose = int.parse(meta?[0] ?? '0');
    final recs = meta?.sublist(1);
    final lyrichords = lines.sublist(divider + 1).join("\n");
    return SongData(
      title: title,
      artist: artist,
      tags: tags,
      transpose: transpose,
      lyrichords: lyrichords,
      recordings: recs,
    );
  }

  SongData({
    required this.title,
    required this.artist,
    required this.tags,
    this.lyrichords = "",
    this.transpose = 0,
    List<String>? recordings,
  }) : recordings = recordings ?? [];

  SongData.fromJson(
    Map<String, dynamic> json,
    List<String> tagList,
    Repertory repertory,
  ) : this(
          title: json["title"],
          artist: json["artist"],
          tags: List<int>.from(json["tags"])
              .map((index) => tagList[index])
              .toSet(),
        );

  SongData.from(SongData source)
      : this(
          title: source.title,
          artist: source.artist,
          tags: Set.from(source.tags),
          lyrichords: source.lyrichords,
          transpose: source.transpose,
          recordings: source.recordings,
        );
}

class Voice {
  final String type;
  final IconData icon;

  const Voice(this.type, this.icon);

  static const Voice CHORDS = Voice("Chords", Icons.more_vert);
}

class Repertory {
  final Directory directory;
  final Directory recordings;
  final Set<Song> songs = {};

  Repertory(this.directory)
      : recordings = Directory(join(directory.path, 'recordings'))
          ..create(recursive: true);

  get isEmpty => songs.isEmpty;

  Set<String> getAllArtists() => songs.map((s) => s.data.artist).toSet();

  Set<String> getAllTags() {
    Set<String> out = {};
    songs.forEach((song) => out.addAll(song.data.tags));
    return out;
  }

  void loadAllSongs(void Function(Song song) onLoaded) {
    var filestream = directory.list();
    filestream.listen((fse) async {
      if (fse is File) {
        var song = await _loadSong(fse);
        onLoaded(song);
      }
    });
  }

  Future<Song> _loadSong(File file) async {
    var s = await file.readAsString();
    var timestamp = int.parse(s.substring(0, s.indexOf("\n")));
    var song = Song(
      SongData.parse(s.substring(s.indexOf("\n") + 1)),
      this,
      timestamp,
    );
    songs.add(song);
    return song;
  }
}
