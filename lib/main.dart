import 'dart:convert';
import 'dart:io';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';

import 'repertory.dart';

bool changes = false;

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
  Repertory repertory;

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

  void refreshSongs() {
    songs = getSongsSorted();
  }

  @override
  Widget build(BuildContext context) {
    if (repertory == null) {
      repertory = Repertory();
      load();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Repertory"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text("stuff"),
              decoration: BoxDecoration(
                color: Colors.redAccent,
              ),
            ),
            ListTile(
              title: Text('Item 1'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Text('Item 2'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
          ],
        ),
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
                    onPressed: changes ? () => {save(snackCtx: ctx)} : null,
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
                    : ListView(
                        children: songs.map((s) => buildSong(s)).toList(),
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
            builder: (ctx) => EditSong(
                song: Song(title: "", artist: "", structure: Structure.basic()),
                repertory: repertory,
                autofocus: true))).then((v) {
      setState(() {
        refreshSongs();
      });
    });
  }

  Widget buildSong(Song song) {
    return ListTile(
      title: Text(song.description),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          setState(() {
            repertory.songs.remove(song);
          });
        },
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (ctx) => EditSong(
                      song: song,
                      repertory: repertory,
                    ))).then((v) {
          setState(() {
            refreshSongs();
          });
        });
      },
    );
  }

  Future<File> file() async {
    var dir = await getExternalStorageDirectory();
    return File("${dir.path}/repertoire.fwd");
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
      changes = false;
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

class EditSong extends StatefulWidget {
  final Song song;
  final Repertory repertory;
  final bool autofocus;

  const EditSong(
      {Key key,
      @required this.song,
      @required this.repertory,
      this.autofocus = false})
      : super(key: key);

  @override
  _EditSongState createState() => _EditSongState();
}

class _EditSongState extends State<EditSong> {
  TextEditingController _cTitle;
  AutoCompleteTextField<String> _artistField;
  AutoCompleteTextField<Tag> _tagAddField;
  Set<Tag> tags;

  void initState() {
    super.initState();
    tags = widget.song.tags.toSet();
    _cTitle = TextEditingController(text: widget.song.title);
    resetArtistField();
    resetTagAddField();
  }

  void resetArtistField() {
    void Function(String) next = (s) {
      _artistField.textField.onChanged(_artistField.controller.text);
      _tagAddField.focusNode.requestFocus();
    };
    GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();
    _artistField = AutoCompleteTextField<String>(
      focusNode: FocusNode(),
      controller: TextEditingController(text: widget.song.artist),
      decoration: InputDecoration(hintText: "Artist..."),
      key: key,
      suggestions: widget.repertory.getAllArtists().toList(growable: false),
      clearOnSubmit: false,
      submitOnSuggestionTap: true,
      textInputAction: TextInputAction.next,
      textSubmitted: next,
      textChanged: (s) {},
      itemBuilder: (context, item) {
        String q = _artistField.controller.text;
        int index = item.toLowerCase().indexOf(q.toLowerCase());
        return Padding(
            padding: EdgeInsets.all(8.0),
            child: RichText(
              text: TextSpan(
                  style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(text: item.substring(0, index)),
                    TextSpan(
                        text: item.substring(index, index + q.length),
                        style: TextStyle(backgroundColor: Colors.red[100])),
                    TextSpan(text: item.substring(index + q.length))
                  ]),
            ));
      },
      itemSorter: (a, b) {
        if (Song.artistSortCut(a)
            .toLowerCase()
            .startsWith(_artistField.controller.text.toLowerCase())) {
          return -1;
        }
        if (Song.artistSortCut(b)
            .toLowerCase()
            .startsWith(_artistField.controller.text.toLowerCase())) {
          return 1;
        }
        return a.toLowerCase().compareTo(b.toLowerCase());
      },
      itemFilter: (item, query) {
        return item.toLowerCase().contains(query.toLowerCase());
      },
      itemSubmitted: next,
    );
  }

  void resetTagAddField() {
    GlobalKey<AutoCompleteTextFieldState<Tag>> key = new GlobalKey();
    _tagAddField = AutoCompleteTextField<Tag>(
      focusNode: FocusNode(),
      controller: TextEditingController(text: ""),
      decoration: InputDecoration(hintText: "New tag..."),
      key: key,
      textInputAction: TextInputAction.next,
      suggestions: widget.repertory.getAllTags().toList(),
      clearOnSubmit: false,
      submitOnSuggestionTap: false,
      textSubmitted: (s) {
        if (s.length > 0) {
          addTag(Tag(name: s));
        }
      },
      textChanged: (s) {},
      itemBuilder: (context, item) {
        return GestureDetector(
            onTap: () {
              addTag(item);
            },
            behavior: HitTestBehavior.opaque,
            child:
                Padding(padding: EdgeInsets.all(8.0), child: Text(item.name)));
      },
      itemSorter: (a, b) {
        return a.name.compareTo(b.name);
      },
      itemFilter: (item, query) {
        return item.name.toLowerCase().startsWith(query.toLowerCase());
      },
      itemSubmitted: (item) {
        addTag(item);
      },
    );
  }

  void addTag(Tag tag) {
    setState(() {
      tags.add(tag);
      if (!_tagAddField.suggestions.contains(tag.name)) {
        _tagAddField.addSuggestion(tag);
      }
      _tagAddField.clear();
    });
  }

  bool didChange() {
    return widget.song.title != _cTitle.text ||
        widget.song.artist != _artistField.controller.text ||
        !SetEquality().equals(tags, widget.song.tags);
  }

  void applyChanges() {
    widget.song.title = _cTitle.text;
    widget.song.artist = _artistField.controller.text;
    widget.song.tags = tags;
    widget.repertory.songs.add(widget.song);
    changes = true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!didChange()) {
          return true;
        }
        return await showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: Text("Close without saving?"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FlatButton.icon(
                      icon: Icon(Icons.done),
                      label: Text("Save changes"),
                      onPressed: () {
                        applyChanges();
                        Navigator.pop(ctx, true);
                      },
                    ),
                    FlatButton.icon(
                      icon: Icon(Icons.cancel),
                      label: Text("Discard changes"),
                      onPressed: () {
                        Navigator.pop(ctx, true);
                      },
                    )
                  ],
                ),
              );
            });
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Edit song details")),
        body: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            Column(
              // Text fields (title, artist)
              children: <Widget>[
                TextField(
                  controller: _cTitle,
                  decoration: InputDecoration(hintText: "Title..."),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (s) {
                    _artistField.focusNode.requestFocus();
                  },
                  autofocus: widget.autofocus,
                ),
                _artistField,
              ],
            ),
            Wrap(
              children: tags
                  .map((tag) => Chip(
                        label: Text(tag.name),
                        deleteIcon: Icon(Icons.cancel),
                        onDeleted: () {
                          setState(() {
                            tags.remove(tag);
                          });
                        },
                      ))
                  .toList(),
            ),
            Container(
              height: 50,
              child: Row(
                children: <Widget>[
                  Expanded(child: _tagAddField),
                  FlatButton.icon(
                    icon: Icon(Icons.add_circle),
                    label: Text("Add"),
                    onPressed: () {
                      _tagAddField.triggerSubmitted();
                    },
                  )
                ],
              ),
            ),
            Column(
              children: List.from(widget.song.structure.sections
                  .map((a) => SectionWidget(area: a)))
                ..addAll([
                  TextField(
                    maxLines: 5,
                    keyboardType: TextInputType.text,
                    onSubmitted: (v) {
                      var lyrics = List<Lyric>();
                      for (String s in v.split("\n")) {
                        if (s.isNotEmpty) {
                          lyrics.add(Lyric(s.trim()));
                        }
                      }
                      widget.song.structure.sections
                          .clear(); // clear all sections, might be problematic?
                      widget.song.structure.sections.add(Section(
                          ChordsElement(chords: []),
                          LyricsElement(lyrics: lyrics)));
                    },
                  )
                ]),
            )
          ],
        ),
        bottomNavigationBar: Container(
          height: 50,
          child: Row(
            children: <Widget>[
              FlatButton.icon(
                icon: Icon(Icons.done),
                label: Text("Done"),
                onPressed: () {
                  applyChanges();
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
