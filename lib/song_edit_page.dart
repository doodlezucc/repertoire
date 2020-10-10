import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';

import 'repertory.dart';

class SongEditPage extends StatefulWidget {
  final Song song;
  final bool autofocus;

  const SongEditPage({Key key, @required this.song, this.autofocus = false})
      : super(key: key);

  @override
  _SongEditPageState createState() => _SongEditPageState();
}

class _SongEditPageState extends State<SongEditPage> {
  SongData data;
  AutoCompleteTextField<String> _artistField;
  AutoCompleteTextField<String> _tagAddField;

  void initState() {
    super.initState();
    data = SongData.from(widget.song.data);
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
      controller: TextEditingController(text: data.artist),
      decoration: InputDecoration(hintText: "Artist..."),
      key: key,
      suggestions:
          widget.song.repertory.getAllArtists().toList(growable: false),
      clearOnSubmit: false,
      submitOnSuggestionTap: true,
      textInputAction: TextInputAction.next,
      textSubmitted: next,
      textChanged: (s) {
        data.artist = s;
      },
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
        if (SongData.artistSortCut(a)
            .toLowerCase()
            .startsWith(_artistField.controller.text.toLowerCase())) {
          return -1;
        }
        if (SongData.artistSortCut(b)
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
    GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();
    _tagAddField = AutoCompleteTextField<String>(
      focusNode: FocusNode(),
      controller: TextEditingController(text: ""),
      decoration: InputDecoration(hintText: "New tag..."),
      key: key,
      textInputAction: TextInputAction.next,
      suggestions: widget.song.repertory.getAllTags().toList(),
      clearOnSubmit: false,
      submitOnSuggestionTap: false,
      textSubmitted: (s) {
        if (s.length > 0) {
          addTag(s);
        }
      },
      textChanged: (s) {},
      itemBuilder: (context, item) {
        return GestureDetector(
            onTap: () {
              addTag(item);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: EdgeInsets.all(8.0), child: Text(item)));
      },
      itemSorter: (a, b) {
        return a.compareTo(b);
      },
      itemFilter: (item, query) {
        return item.toLowerCase().startsWith(query.toLowerCase());
      },
      itemSubmitted: (item) {
        addTag(item);
      },
    );
  }

  void addTag(String tag) {
    setState(() {
      data.tags.add(tag);
      if (!_tagAddField.suggestions.contains(tag)) {
        _tagAddField.addSuggestion(tag);
      }
      _tagAddField.clear();
    });
  }

  bool didChange() {
    return !widget.song.data.matches(data);
  }

  void applyChanges() {
    widget.song.setData(data);
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
                  controller: TextEditingController(text: data.title),
                  decoration: InputDecoration(hintText: "Title..."),
                  textInputAction: TextInputAction.next,
                  onChanged: (s) => data.title = s,
                  onSubmitted: (s) {
                    _artistField.focusNode.requestFocus();
                  },
                  autofocus: widget.autofocus,
                ),
                _artistField,
              ],
            ),
            Wrap(
              children: data.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: Icon(Icons.cancel),
                        onDeleted: () {
                          setState(() {
                            data.tags.remove(tag);
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
            Text(data.lyrichords),
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
