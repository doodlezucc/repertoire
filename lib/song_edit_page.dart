import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import 'autocomplete.dart';
import 'keyboard_visibility.dart';
import 'lyrichords/display.dart';
import 'lyrichords/edit.dart';
import 'mini_player.dart';
import 'repertory.dart';
import 'web_extractors/ge.dart';
import 'web_extractors/ug.dart';

final record = Record();

class DownloadButton extends StatefulWidget {
  final SongData data;
  final void Function() onDownloaded;
  final bool withChords;

  const DownloadButton({
    Key? key,
    required this.data,
    required this.onDownloaded,
    required this.withChords,
  }) : super(key: key);

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: " + result.toString())));
      });
    }
  }
}

class SongEditPage extends StatefulWidget {
  final Song song;
  final bool isCreation;

  const SongEditPage({
    Key? key,
    required this.song,
    this.isCreation = false,
  }) : super(key: key);

  @override
  _SongEditPageState createState() => _SongEditPageState();
}

class _SongEditPageState extends State<SongEditPage> {
  late SongData data;
  late TextEditingController _artistCtrl;
  late TextEditingController _tagAddCtrl;
  final _artistFocus = FocusNode();
  final _tagFocus = FocusNode();
  final chordCtrl = ChordSuggestionsController();
  final focusNode = FocusNode();
  final players = Map<String, AudioPlayer>();

  var editLyrichords = false;
  var isRecording = false;
  var isSwitchingRecording = false;

  void initState() {
    super.initState();
    data = SongData.from(widget.song.data);
    _artistCtrl = TextEditingController(text: data.artist);
    _artistCtrl.addListener(() => data.artist = _artistCtrl.text);
    _tagAddCtrl = TextEditingController();
    editLyrichords = widget.isCreation || data.lyrichords.isEmpty;
    focusNode.addListener(() => setState(() {}));

    for (var path in data.recordings) {
      players[path] = AudioPlayer();
    }
  }

  @override
  void dispose() {
    if (isRecording) {
      record.stop();
    }
    players.values.forEach((player) => player.dispose());
    super.dispose();
  }

  void addTag(String tag) {
    setState(() {
      data.tags.add(tag);
      _tagAddCtrl.clear();
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
    setState(() {});
  }

  void toggleRecording() async {
    setState(() => isSwitchingRecording = true);

    if (!isRecording) {
      if (await record.hasPermission()) {
        var dir = widget.song.repertory.recordings;
        var now = DateTime.now().millisecondsSinceEpoch;
        var name = '$now.aac';
        var path = p.join(dir.path, name);
        await record.start(path: path);
        isRecording = true;
      }
    } else {
      var path = await record.stop();
      if (path != null) {
        print('added path "$path"');
        widget.song.data.recordings.add(path);
        players[path] = AudioPlayer();
      }
      isRecording = false;
    }

    setState(() => isSwitchingRecording = false);
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
                    TextButton.icon(
                      icon: Icon(Icons.done),
                      label: Text("Save changes"),
                      onPressed: () {
                        applyChanges();
                        Navigator.pop(ctx, true);
                      },
                    ),
                    TextButton.icon(
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
                                autofocus: widget.isCreation,
                              ),
                              AutocompleteField(
                                hintText: 'Artist...',
                                focusNode: _artistFocus,
                                controller: _artistCtrl,
                                optionsBuilder: containMatcher(
                                    widget.song.repertory.getAllArtists()),
                              ),
                            ],
                          ),
                          Wrap(
                            children: data.tags
                                .map((tag) => Chip(
                                      label: Text(tag),
                                      deleteIcon: Icon(Icons.cancel),
                                      onDeleted: () => setState(() {
                                        data.tags.remove(tag);
                                      }),
                                    ))
                                .toList(),
                          ),
                          Container(
                            height: 50,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: AutocompleteField(
                                    hintText: 'Add tag...',
                                    focusNode: _tagFocus,
                                    controller: _tagAddCtrl,
                                    optionsBuilder: containMatcher(
                                        widget.song.repertory.getAllTags()),
                                    onSelected: addTag,
                                    onChanged: (s) => setState(() {}),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: Icon(Icons.add_circle),
                                  label: Text("Add"),
                                  onPressed: _tagAddCtrl.text.isEmpty
                                      ? null
                                      : () => addTag(_tagAddCtrl.text),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: TextButton(
                          child: Text('Edit mode'),
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all(StadiumBorder()),
                            backgroundColor: MaterialStateProperty.all(
                              editLyrichords
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).highlightColor,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              editLyrichords
                                  ? Colors.white
                                  : Theme.of(context).textTheme.button!.color,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              editLyrichords = !editLyrichords;
                            });
                          }),
                    ),
                    Visibility(
                      visible: !editLyrichords,
                      child: Center(
                        child: NumberPicker(
                          minValue: -11,
                          maxValue: 11,
                          haptics: true,
                          itemCount: 5,
                          textMapper: (s) =>
                              (s[0] == '-' || s == '0') ? s : '+$s',
                          textStyle: TextStyle(fontSize: 12),
                          selectedTextStyle: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          value: data.transpose,
                          onChanged: (v) => setState(() => data.transpose = v),
                          axis: Axis.horizontal,
                          itemWidth: 50,
                          itemHeight: 40,
                        ),
                      ),
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
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: players.entries.expand((e) {
                          return [
                            MiniPlayer(player: e.value, source: e.key),
                            SizedBox(height: 8),
                          ];
                        }).toList(),
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
        persistentFooterButtons: [
          TextButton.icon(
            icon: Icon(isRecording ? Icons.save : Icons.mic),
            label: Text(isRecording ? "Recording..." : "Record"),
            onPressed: toggleRecording,
            style: isRecording
                ? ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red[300]),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  )
                : null,
          ),
          TextButton.icon(
            icon: Icon(Icons.done),
            label: Text("Done"),
            onPressed: () {
              applyChanges();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
