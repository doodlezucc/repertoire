import 'dart:math';

import 'package:flutter/material.dart';

import 'music_theory.dart';
import 'repertory.dart';

class LyrichordsField extends StatefulWidget {
  final SongData data;
  final ChordSuggestionsController chordCtrl;

  const LyrichordsField(
      {Key key, @required this.data, @required this.chordCtrl})
      : super(key: key);

  @override
  _LyrichordsFieldState createState() => _LyrichordsFieldState();
}

class _LyrichordsFieldState extends State<LyrichordsField> {
  TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController(text: widget.data.lyrichords);
    resetChordController();
    widget.chordCtrl.addListener(() {
      onChordUpdate();
    });
  }

  void onChordUpdate() {
    //print("Chord update");
  }

  void resetChordController() {
    widget.chordCtrl.onPitchSelected = (pitch) {
      int cursor = ctrl.value.selection.baseOffset + 1;

      String text = "\n" + ctrl.text;

      int lineStart = text.lastIndexOf("\n", cursor - 1) + 1;
      int indexInLine = cursor - lineStart;
      int aboveLineStart =
          (lineStart == 1) ? 0 : (text.lastIndexOf("\n", lineStart - 2) + 1);
      String aboveLine = text.substring(aboveLineStart, lineStart - 1);

      bool makeNewLine = aboveLineStart == 0;

      if (!makeNewLine && aboveLine.length + 2 > indexInLine) {
        if (indexInLine > 0) {
          // make new line only if line doesn't start with two spaces
          makeNewLine =
              !(aboveLine + "  ").substring(indexInLine - 1).startsWith("   ");
        } else {
          // cursor is at start of line
          // make new line only if line doesn't start with two spaces
          makeNewLine = !(aboveLine + "  ").startsWith("  ");
        }
      }

      if (makeNewLine) {
        aboveLineStart += aboveLine.length + 1;
        aboveLine = (" " * indexInLine) + pitch.name;
      } else {
        if (aboveLine.length < indexInLine) {
          aboveLine += " " * (indexInLine - aboveLine.length) + pitch.name;
        } else {
          // merge chord into line above and surround it by spaces
          String untouchedTail = aboveLine.length >
                  indexInLine + pitch.name.length + 1
              ? " " + aboveLine.substring(indexInLine + pitch.name.length + 1)
              : null;
          if (indexInLine > 0) {
            aboveLine =
                aboveLine.substring(0, indexInLine - 1) + " " + pitch.name;
          } else {
            aboveLine = pitch.name;
          }
          if (untouchedTail != null) {
            aboveLine += untouchedTail;
          }
        }
      }

      text = text.substring(0, aboveLineStart) +
          aboveLine +
          "\n" +
          text.substring(lineStart);

      if (text.startsWith("\n")) {
        text = text.substring(1);
      }
      widget.data.lyrichords = text;
      ctrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
            offset: aboveLineStart + indexInLine + pitch.name.length - 1),
      );
    };
    widget.chordCtrl.onChordSelected = (chord) {
      widget.chordCtrl.value = ChordSuggestionValue(0);
    };
  }

  @override
  Widget build(BuildContext context) {
    resetChordController();
    return Column(
      children: [
        TextField(
          maxLines: null,
          controller: ctrl,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (s) {
            widget.data.lyrichords = s;
          },
          style: TextStyle(
              fontFamily: "CourierPrime", fontSize: 14, color: Colors.black),
        ),
      ],
    );
  }
}

class ChordSuggestions extends StatefulWidget {
  final ChordSuggestionsController controller;

  const ChordSuggestions({Key key, @required this.controller})
      : super(key: key);

  @override
  _ChordSuggestionsState createState() => _ChordSuggestionsState();
}

class _ChordSuggestionsState extends State<ChordSuggestions> {
  ClampedPitch pitch;

  void selectPitch(ClampedPitch p) {
    pitch = p;
    widget.controller.value = ChordSuggestionValue(1);
    widget.controller.onPitchSelected(p);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    int i = 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
      ),
      height: Suggestion.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.controller.value.stage == 0
            ? ClampedPitch.whiteKeys.map(
                (key) {
                  final keyIndex = i++;
                  return Suggestion(
                    main: TapText(key, () {
                      selectPitch(ClampedPitch(keyIndex, Modification.NONE));
                    }),
                    above: TapText("$key♭", () {
                      selectPitch(ClampedPitch(keyIndex, Modification.FLAT));
                    }),
                    below: TapText("$key♯", () {
                      selectPitch(ClampedPitch(keyIndex, Modification.SHARP));
                    }),
                  );
                },
              ).toList()
            : ChordType.values
                .map((e) => Suggestion(
                      main: TapText(pitch.name + e.abbreviation, () {
                        widget.controller.onChordSelected(Chord(pitch, e));
                      }),
                    ))
                .toList(),
      ),
    );
  }
}

class ChordSuggestionValue {
  final int stage;

  ChordSuggestionValue(this.stage);
}

class ChordSuggestionsController extends ValueNotifier<ChordSuggestionValue> {
  void Function(ClampedPitch pitch) onPitchSelected = (p) {};
  void Function(Chord chord) onChordSelected = (c) {};

  ChordSuggestionsController() : super(ChordSuggestionValue(0));
}

class TapText {
  final String text;
  final void Function() action;

  TapText(this.text, this.action);
}

class Suggestion extends StatefulWidget {
  static const height = 36.0;
  static const center = height * 0.75;

  final TapText main;
  final TapText above;
  final TapText below;

  const Suggestion({this.main, this.above, this.below, Key key})
      : super(key: key);

  @override
  _SuggestionState createState() => _SuggestionState();
}

class _SuggestionState extends State<Suggestion> {
  ScrollController ctrl;

  bool get isMultiple => widget.above != null && widget.below != null;

  @override
  void initState() {
    ctrl = ScrollController(initialScrollOffset: Suggestion.center);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.main.action();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          height: Suggestion.height,
          clipBehavior: Clip.antiAlias,
          child: !isMultiple
              ? SuggestionTile(widget.main.text, position: 0)
              : NotificationListener<ScrollNotification>(
                  onNotification: (notif) {
                    if (notif is ScrollEndNotification) {
                      var diff = ctrl.position.pixels - Suggestion.center;
                      if (diff < 0) {
                        widget.above.action();
                      } else {
                        widget.below.action();
                      }
                    }
                    return true;
                  },
                  child: SingleChildScrollView(
                    physics: ClampingScrollPhysics(),
                    controller: ctrl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SuggestionTile(widget.above.text, position: 1),
                        SuggestionTile(widget.main.text, position: 0),
                        SuggestionTile(widget.below.text, position: -1),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class SuggestionTile extends StatelessWidget {
  final String text;
  final int position;

  const SuggestionTile(this.text, {Key key, this.position}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Suggestion.height * (position == 0 ? 1 : 0.75),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (position == 1) Expanded(child: Container()),
          Center(
            child: Text(text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                )),
          ),
          if (position == -1) Expanded(child: Container()),
        ],
      ),
    );
  }
}
