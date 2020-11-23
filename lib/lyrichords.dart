import 'dart:math';

import 'package:flutter/material.dart';

import 'music_theory.dart';
import 'repertory.dart';

class LyrichordsField extends StatefulWidget {
  final SongData data;
  final ChordSuggestionsController chordCtrl;
  final FocusNode focusNode;

  const LyrichordsField(
      {Key key, @required this.data, @required this.chordCtrl, this.focusNode})
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
    setState(() {
      ctrl.value = TextEditingValue(
          text: widget.data.lyrichords,
          composing: ctrl.value.composing,
          selection: ctrl.value.selection);
    });
  }

  static bool containsChords(String s) {
    // Based on https://stackoverflow.com/a/29146707/10258754
    return s.contains(
        "(^| )([A-G](##?|bb?)?((m|sus|maj|min|aug|dim)\d?)?(\/[A-G](##?|bb?)?)?)( (?!\\w)|\$)");
  }

  void resetChordController() {
    widget.chordCtrl.onPitchSelected = (pitch) {};
    widget.chordCtrl.onChordSelected = (chord) {
      widget.chordCtrl.value = ChordSuggestionValue(0);
      int cursor = ctrl.value.selection.baseOffset + 1;

      String name = chord.nameAbbreviated;

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
        aboveLine = (" " * indexInLine) + name;
      } else {
        if (aboveLine.length < indexInLine) {
          aboveLine += " " * (indexInLine - aboveLine.length) + name;
        } else {
          // merge chord into line above and surround it by spaces
          String untouchedTail =
              aboveLine.length > indexInLine + name.length + 1
                  ? " " + aboveLine.substring(indexInLine + name.length + 1)
                  : null;
          if (indexInLine > 0) {
            aboveLine = aboveLine.substring(0, indexInLine - 1) + " " + name;
          } else {
            aboveLine = name;
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
            offset: aboveLineStart + indexInLine + name.length - 1),
      );
    };
  }

  int getLongestLine() {
    return widget.data.lyrichords
        .split("\n")
        .fold(0, (len, line) => max(len, line.length));
  }

  void onTextChanged(String s) {
    if (s.length > widget.data.lyrichords.length) {
      // text is added
      int pos = ctrl.selection.baseOffset;
      if (s[pos - 1] == "\n") {
        // user wants newline
        bool isTopLine = s.indexOf("\n") == pos - 1;
        if (!isTopLine) {
          int posInLine = pos - s.lastIndexOf("\n", pos - 2) - 2;

          int lineAboveStart = s.lastIndexOf("\n", pos - posInLine - 3) + 1;

          String lineAbove = s.substring(lineAboveStart);
          lineAbove = lineAbove.substring(0, lineAbove.indexOf("\n"));

          print(lineAbove);
          print(containsChords(lineAbove));

          if (containsChords(lineAbove)) {
            String unshiftedLyrics = s.substring(pos - posInLine - 1, pos - 1);
            int off = -(unshiftedLyrics.length -
                (unshiftedLyrics = unshiftedLyrics.trimRight()).length);

            String shiftedLyrics = s.substring(pos);
            shiftedLyrics =
                shiftedLyrics.substring(0, shiftedLyrics.indexOf("\n"));

            String unshiftedChords = lineAbove.substring(0, posInLine);
            off -= unshiftedChords.length -
                (unshiftedChords = unshiftedChords.trimRight()).length;

            if (lineAbove.length > posInLine) {
              // do the wrap thing
              s = widget.data.lyrichords;
              s = s.replaceRange(
                  lineAboveStart,
                  pos - 1,
                  "$unshiftedChords\n$unshiftedLyrics\n" +
                      lineAbove.substring(posInLine) +
                      "\n");
              ctrl.value = TextEditingValue(
                  text: s,
                  selection: TextSelection.collapsed(offset: pos + off - 1));
            }
          }
        }
      }
    }

    setState(() {
      widget.data.lyrichords = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    resetChordController();
    var textStyle = Theme.of(context).textTheme.overline;
    double charWidth = textStyle.fontSize * 0.76;
    double inset = 12;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        width: charWidth * getLongestLine() + inset * 2.25,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextField(
            maxLines: null,
            controller: ctrl,
            autocorrect: false,
            enableSuggestions: false,
            focusNode: widget.focusNode,
            onChanged: onTextChanged,
            cursorColor: textStyle.color,
            decoration: InputDecoration(
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.grey[300],
              contentPadding:
                  EdgeInsets.symmetric(horizontal: inset, vertical: 10),
              hintText: "Write some lyrics or chords here...",
              hintStyle: TextStyle(color: Colors.grey[800]),
            ),
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

class ChordSuggestions extends StatefulWidget {
  final ChordSuggestionsController controller;
  final bool visible;

  const ChordSuggestions(
      {Key key, @required this.controller, this.visible = true})
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
    if (!widget.visible) return SizedBox.shrink();

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
