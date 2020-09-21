import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repertories/song_edit_page.dart';

import 'repertory.dart';
import 'song_list_tile.dart';

bool _somethingChanged = false;

void markAsUnsaved() {
  _somethingChanged = true;
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Repertory",
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
  Repertory repertory = Repertory();

  static const int SORT_TITLE = 0;
  static const int SORT_ARTIST = 1;
  static const int SORT_DATE = 2;

  int sortMethod = SORT_DATE;
  List<Song> songs = [];

  bool _debugSave = false;

  List<Song> getSongsSorted() {
    switch (sortMethod) {
      case SORT_TITLE:
        return repertory.songs.toList()
          ..sort((a, b) {
            if (a.title == b.title) {
              return a.artistSort.compareTo(b.artistSort);
            }
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });
      case SORT_ARTIST:
        return repertory.songs.toList()
          ..sort((a, b) {
            if (a.artist == b.artist) {
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            }
            if (b.artist.isEmpty) {
              return -1;
            }
            if (a.artist.isEmpty) {
              return 1;
            }
            return a.artistSort.compareTo(b.artistSort);
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
        title: Text("Repertory"),
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
                    onPressed:
                        _somethingChanged ? () => {save(snackCtx: ctx)} : null,
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
                child: repertory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              "This repertory is empty",
                            ),
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
                              repertory.songs.remove(songs[index]);
                              markAsUnsaved();
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
                song: Song(
                  title: "",
                  artist: "",
                  structure: Structure.basic(),
                  repertory: repertory,
                ),
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

  void save({BuildContext snackCtx}) async {
    var j = repertory.toJson();
    var str = jsonEncode(j);
    (await file()).writeAsString(str);
    if (snackCtx != null) {
      Scaffold.of(snackCtx).showSnackBar(SnackBar(
        content: Text("Saved!"),
        duration: Duration(milliseconds: 1000),
      ));
    }
    if (_debugSave) {
      print("Saved the following:");
      printJson(j);
    } else {
      print("Saved to file");
    }
    setState(() {
      _somethingChanged = false;
    });
  }

  void load() async {
    if (!(await file()).existsSync()) {
      return;
    }
    String s = await (await file()).readAsString();
    var j = jsonDecode(s);
    if (_debugSave) {
      printJson(j);
    }
    setState(() {
      repertory = Repertory.fromJson(j);
      refreshSongs();
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
