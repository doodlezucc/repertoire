import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Song {
  final Repertory repertory;
  SongData _data;
  SongData get data => _data;
  File _file;
  File get file => _file;

  void save() {
    file.writeAsStringSync(data.saveToString());
    print("Saved " + data.description);
  }

  void _updateFile() {
    _file = File(
        join(repertory.directory.path, data.description.replaceAll("/", "-")) +
            ".txt");
  }

  void remove() {
    print("should be removing this one right now :/");
  }

  Song(SongData data, this.repertory) : _data = data {
    _updateFile();
  }
}

class SongData {
  String title;
  String artist;
  String get artistSort => artistSortCut(artist).toLowerCase();
  Set<String> tags = {};
  String lyrichords;

  String get description {
    String t = title.isEmpty ? "Untitled" : title;
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

  SongData({
    @required String title,
    @required String artist,
    @required this.tags,
    this.lyrichords = "",
  })  : title = title,
        artist = artist;

  String saveToString() {
    return [
      title,
      artist,
      tags.map((e) => e.replaceAll(",", "\\,")).join(","),
      "",
      lyrichords,
    ].join("\n");
  }

  SongData.parse(String s) {
    var lines = s.split("\n");
    title = lines[0];
    artist = lines[1];
    var line = lines[2];
    tags = line.length > 0
        ? lines[2].split(",").map((e) => e.replaceAll("\\,", ",")).toSet()
        : {};

    lyrichords = lines.sublist(4).join("\n");
  }

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
}

class Voice {
  final String type;
  final IconData icon;

  const Voice(this.type, this.icon);

  static const Voice CHORDS = Voice("Chords", Icons.more_vert);
}

class Repertory {
  Directory directory;

  Set<Song> songs = {};

  Repertory(this.directory);

  get isEmpty => songs.isEmpty;

  Set<String> getAllArtists() => songs.map((s) => s.data.artist).toSet();

  Set<String> getAllTags() {
    Set<String> out = {};
    songs.forEach((song) => out.addAll(song.data.tags));
    return out;
  }

  @deprecated
  Repertory.fromJson(Map<String, dynamic> json, void Function() onDone) {
    getExternalStorageDirectory().then((dir) {
      directory = Directory(join(dir.path, "Repertoir"));
      directory.createSync(recursive: true);

      List<String> tagList = List.from(json["tags"])
          .map<String>((jtag) => jtag["name"])
          .toList(growable: false);

      songs = List.from(json["songs"])
          .map((j) => Song(SongData.fromJson(j, tagList, this), this))
          .toSet();

      onDone();
    });
  }

  void loadAllSongs(void Function(Song song) onLoaded) {
    var filestream = directory.list();
    filestream.listen((file) async {
      var song = await _loadSong(file);
      onLoaded(song);
    });
  }

  Future<Song> _loadSong(File file) async {
    var song = Song(SongData.parse(await file.readAsString()), this);
    songs.add(song);
    return song;
  }
}
