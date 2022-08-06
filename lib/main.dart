import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:repertoire/tuner/tuner.dart';

import 'repertory.dart';
import 'song_edit_page.dart';
import 'song_list_tile.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Repertoire",
      theme: ThemeData(
        primarySwatch: Colors.red,
        textTheme: TextTheme(
          overline: TextStyle(
            fontFamily: "FiraCode",
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(shape: MaterialStateProperty.all(StadiumBorder())),
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Repertory repertory;

  static const int SORT_TITLE = 0;
  static const int SORT_ARTIST = 1;
  static const int SORT_DATE = 2;
  static const int SORT_RANDOM = 3;

  int sortMethod = SORT_DATE;
  List<Song> songs = [];

  bool isLoading = false;

  List<Song> getSongsSorted() {
    switch (sortMethod) {
      case SORT_TITLE:
        return repertory.songs.toList()
          ..sort((a, b) {
            if (a.data.title == b.data.title) {
              return a.data.artistSort.compareTo(b.data.artistSort);
            }
            return a.data.title
                .toLowerCase()
                .compareTo(b.data.title.toLowerCase());
          });
      case SORT_ARTIST:
        return repertory.songs.toList()
          ..sort((a, b) {
            if (a.data.artist == b.data.artist) {
              return a.data.title
                  .toLowerCase()
                  .compareTo(b.data.title.toLowerCase());
            }
            if (b.data.artist.isEmpty) {
              return -1;
            }
            if (a.data.artist.isEmpty) {
              return 1;
            }
            return a.data.artistSort.compareTo(b.data.artistSort);
          });
      case SORT_DATE:
        return repertory.songs.toList()
          ..sort((a, b) {
            return -a.creationTimestamp.compareTo(b.creationTimestamp);
          });
      case SORT_RANDOM:
        var l = List<Song>.from(repertory.songs);
        return l..shuffle();
    }
    return repertory.songs.toList();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  void refreshSongs() {
    setState(() {
      songs = getSongsSorted();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Repertoire"),
      ),
      body: Builder(
        builder: (ctx) => Column(
          children: <Widget>[
            Container(
              height: 50,
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.multitrack_audio),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => TunerPage(),
                      ));
                    },
                  ),
                  // IconButton(
                  //   icon: Icon(Icons.insert_drive_file),
                  //   onPressed: load,
                  // ),
                  Expanded(
                    child: Container(),
                  ),
                  DropdownButton<int>(
                    items: [
                      DropdownMenuItem(
                          value: SORT_TITLE, child: Text("by Title")),
                      DropdownMenuItem(
                          value: SORT_ARTIST, child: Text("by Artist")),
                      DropdownMenuItem(
                          value: SORT_DATE, child: Text("by Date")),
                      DropdownMenuItem(
                          value: SORT_RANDOM, child: Text("Random"))
                    ],
                    onChanged: (i) {
                      sortMethod = i!;
                      refreshSongs();
                    },
                    value: sortMethod,
                  )
                ],
              ),
            ),
            Expanded(
              child: Container(
                child: isLoading
                    ? Center(child: Text("Loading..."))
                    : repertory.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text("This repertory is empty"),
                                Container(height: 10),
                                FloatingActionButton.extended(
                                    onPressed: letUserAddSong,
                                    label: Text("Add song"))
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemBuilder: (ctx, index) => SongListTile(
                              song: songs[index],
                              onDelete: () {
                                refreshSongs();
                              },
                              onEdited: () {
                                refreshSongs();
                              },
                            ),
                            itemCount: songs.length,
                          ),
              ),
            ),
            Container(
              height: 43,
              child: Row(
                children: <Widget>[
                  // add some elements on the left?
                  Expanded(
                    child: Container(),
                  ),
                  TextButton.icon(
                    onPressed: letUserAddSong,
                    icon: Icon(Icons.add),
                    label: Text("Add Song"),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void letUserAddSong() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) => SongEditPage(
                song: Song(SongData(title: "", artist: "", tags: {}), repertory,
                    DateTime.now().millisecondsSinceEpoch),
                isCreation: true))).then((v) {
      refreshSongs();
    });
  }

  Future<File> file() async {
    var dir = await getExternalStorageDirectory();
    return File("${dir!.path}/repertory.fwd");
  }

  void load() async {
    isLoading = true;
    var extdir = await getExternalStorageDirectory();
    var directory = Directory(path.join(extdir!.path, "Repertoire"));
    if (!await directory.exists()) {
      await directory.create();
      setState(() {
        isLoading = false;
      });
    }
    setState(() {
      repertory = Repertory(directory);
    });
    repertory.loadAllSongs((song) {
      isLoading = false;
      refreshSongs();
    });
  }

  void printJson(var j) {
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    String prettyprint = encoder.convert(j);
    printWrapped(prettyprint);
  }
}

void printWrapped(String text) {
  final pattern = new RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}
