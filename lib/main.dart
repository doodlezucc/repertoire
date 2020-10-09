import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:repertories/song_edit_page.dart';

import 'repertory.dart';
import 'song_list_tile.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Repertoir",
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(),
    );
  }
}

dynamic db(dynamic i) {
  print(i);
  return i;
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Repertory repertory = Repertory(null);

  static const int SORT_TITLE = 0;
  static const int SORT_ARTIST = 1;
  static const int SORT_DATE = 2;

  int sortMethod = SORT_DATE;
  List<Song> songs = [];

  bool _debugSave = false;

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
        return repertory.songs.toList().reversed.toList();
    }
    return repertory.songs.toList();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  void refreshSongs() {
    songs = getSongsSorted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Repertoir"),
      ),
      body: Builder(
        builder: (ctx) => Column(
          children: <Widget>[
            Container(
              height: 50,
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.save),
                    onPressed: () {
                      save(snackCtx: ctx);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.insert_drive_file),
                    onPressed: () => {load()},
                  ),
                  Checkbox(
                    value: _debugSave,
                    onChanged: (v) {
                      setState(() {
                        _debugSave = v;
                      });
                    },
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  DropdownButton(
                    items: [
                      DropdownMenuItem(
                          value: SORT_TITLE, child: Text("by Title")),
                      DropdownMenuItem(
                          value: SORT_ARTIST, child: Text("by Artist")),
                      DropdownMenuItem(value: SORT_DATE, child: Text("by Date"))
                    ],
                    onChanged: (i) {
                      sortMethod = i;
                      setState(() {
                        refreshSongs();
                      });
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
                                setState(() {
                                  songs[index].remove();
                                  repertory.songs.remove(songs[index]);
                                  refreshSongs();
                                });
                              },
                              onEdited: () {
                                setState(() {
                                  refreshSongs();
                                });
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
                  FlatButton.icon(
                    onPressed: letUserAddSong,
                    icon: Icon(Icons.add),
                    label: Text("Add song"),
                  )
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
                song:
                    Song(SongData(title: "", artist: "", tags: {}), repertory),
                autofocus: true))).then((v) {
      setState(() {
        refreshSongs();
      });
    });
  }

  Future<File> file() async {
    var dir = await getExternalStorageDirectory();
    return File("${dir.path}/repertory.fwd");
  }

  @deprecated
  void save({BuildContext snackCtx}) async {
    repertory.songs.forEach((element) {
      element.save();
    });
    if (snackCtx != null) {
      Scaffold.of(snackCtx).showSnackBar(SnackBar(
        content: Text("Saved!"),
        duration: Duration(milliseconds: 1000),
      ));
    }
  }

  void load() async {
    isLoading = true;
    getExternalStorageDirectory().then((dir) {
      var directory = Directory(path.join(dir.path, "Repertoir"));
      repertory = Repertory(directory);
      repertory.loadAllSongs((song) {
        setState(() {
          isLoading = false;
          refreshSongs();
        });
      });
    });
  }

  void printWrapped(String text) {
    final pattern = new RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  void printJson(var j) {
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    String prettyprint = encoder.convert(j);
    printWrapped(prettyprint);
  }
}
