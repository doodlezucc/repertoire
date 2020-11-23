import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';

import 'keyboard_visibility.dart';
import 'lyrichords/display.dart';
import 'lyrichords/edit.dart';
import 'repertory.dart';
import 'web_extractors/ge.dart';
import 'web_extractors/ug.dart';

class SongEditPage extends StatefulWidget {
  final Song song;
  final bool isCreation;

  const SongEditPage({Key key, @required this.song, this.isCreation = false})
      : super(key: key);

  @override
  _SongEditPageState createState() => _SongEditPageState();
}

class DownloadButton extends StatefulWidget {
  final SongData data;
  final void Function() onDownloaded;
  final bool withChords;

  const DownloadButton({Key key, this.data, this.onDownloaded, this.withChords})
      : super(key: key);

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return FlatButton.icon(
      icon: isDownloading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ))
          : Icon(Icons.get_app),
      label: Text("Lyrics" + (widget.withChords ? " with chords" : "")),
      onPressed: isDownloading ? null : findLyrichords,
      shape: StadiumBorder(),
      color: Theme.of(context).accentColor,
      textColor: Colors.white,
      disabledTextColor: Colors.white,
      disabledColor: Theme.of(context).backgroundColor,
    );
  }

  void findLyrichords() async {
    setState(() {
      isDownloading = true;
    });

    String title = widget.data.title;
    String artist = widget.data.artist;

    var result;

    if (widget.withChords)
      result = await UGScraper.findLyrichords(title, artist);
    else
      result = await GeniusScraper.findLyrics(title, artist);

    if (result is String) {
      setState(() {
        isDownloading = false;
        widget.data.lyrichords = result;
        widget.onDownloaded();
      });
    } else {
      setState(() {
        isDownloading = false;
        Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("Error: " + result.toString())));
      });
    }
  }
}

class _SongEditPageState extends State<SongEditPage> {
  SongData data;
  AutoCompleteTextField<String> _artistField;
  AutoCompleteTextField<String> _tagAddField;
  String tagFieldText = "";
  var chordCtrl = ChordSuggestionsController();
  var focusNode = FocusNode();

  var editLyrichords = false;

  void initState() {
    super.initState();
    data = SongData.from(widget.song.data);
    editLyrichords = widget.isCreation || data.lyrichords.isEmpty;
    resetArtistField();
    resetTagAddField();
    focusNode.addListener(() {
      setState(() {});
    });
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
      controller: TextEditingController(text: tagFieldText),
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
      textChanged: (s) {
        setState(() {
          tagFieldText = s;
        });
      },
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
    widget.song.setData(data, isCreation: widget.isCreation);
  }

  void onDownloaded() {
    chordCtrl.value = ChordSuggestionValue(chordCtrl.value.stage);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!didChange()) {
          return true;
        }
        FocusScope.of(context).unfocus();
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
                    ),
                  ],
                ),
              );
            });
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Edit song details")),
        body: KeyboardVisibilityBuilder(
          builder: (context, child, isKeyboardVisible) => Column(
            children: [
              Expanded(
                child: ListView(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0)
                          .copyWith(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            // Text fields (title, artist)
                            children: <Widget>[
                              TextField(
                                controller:
                                    TextEditingController(text: data.title),
                                decoration:
                                    InputDecoration(hintText: "Title..."),
                                textInputAction: TextInputAction.next,
                                onChanged: (s) => data.title = s,
                                onSubmitted: (s) {
                                  _artistField.focusNode.requestFocus();
                                },
                                autofocus: widget.isCreation,
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
                                  onPressed:
                                      _tagAddField.controller.text.isEmpty
                                          ? null
                                          : () {
                                              _tagAddField.triggerSubmitted();
                                            },
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: FlatButton(
                          child: Text('Edit mode'),
                          shape: StadiumBorder(),
                          color: editLyrichords
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).buttonColor,
                          textColor: editLyrichords
                              ? Colors.white
                              : Theme.of(context).textTheme.button.color,
                          onPressed: () {
                            setState(() {
                              editLyrichords = !editLyrichords;
                            });
                          }),
                    ),
                    if (!editLyrichords)
                      LyrichordsDisplayField(
                        data: data,
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    if (editLyrichords)
                      LyrichordsEditField(
                        data: data,
                        chordCtrl: chordCtrl,
                        focusNode: focusNode,
                      ),
                    Center(
                      child: Row(
                        children: [
                          Expanded(child: Container()),
                          DownloadButton(
                            data: data,
                            onDownloaded: onDownloaded,
                            withChords: false,
                          ),
                          Expanded(child: Container()),
                          DownloadButton(
                            data: data,
                            onDownloaded: onDownloaded,
                            withChords: true,
                          ),
                          Expanded(child: Container()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ChordSuggestions(
                controller: chordCtrl,
                visible: isKeyboardVisible && focusNode.hasFocus,
              ),
            ],
          ),
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
