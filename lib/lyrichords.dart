import 'package:flutter/material.dart';

import 'music_theory.dart';
import 'repertory.dart';

class LyrichordsField extends StatefulWidget {
  final SongData data;

  const LyrichordsField({Key key, this.data}) : super(key: key);

  @override
  _LyrichordsFieldState createState() => _LyrichordsFieldState();
}

class _LyrichordsFieldState extends State<LyrichordsField> {
  TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController(text: widget.data.lyrichords);
  }

  @override
  Widget build(BuildContext context) {
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
  final void Function(Chord chord) onChordSelected;

  const ChordSuggestions({Key key, @required this.onChordSelected})
      : super(key: key);

  @override
  _ChordSuggestionsState createState() => _ChordSuggestionsState();
}

class _ChordSuggestionsState extends State<ChordSuggestions> {
  ClampedPitch pitch;

  int get stage => pitch != null ? (1) : 0;

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
        children: stage == 0
            ? ClampedPitch.whiteKeys.map(
                (key) {
                  final keyIndex = i++;
                  return Suggestion(
                    main: TapText(key, () {
                      setState(() {
                        pitch = ClampedPitch(keyIndex, Modification.NONE);
                      });
                    }),
                    above: TapText("$key♭", () {
                      setState(() {
                        pitch = ClampedPitch(keyIndex, Modification.FLAT);
                      });
                    }),
                    below: TapText("$key♯", () {
                      setState(() {
                        pitch = ClampedPitch(keyIndex, Modification.SHARP);
                      });
                    }),
                  );
                },
              ).toList()
            : ChordType.values
                .map((e) => Suggestion(
                      main: TapText(pitch.name + e.abbreviation, () {
                        widget.onChordSelected(Chord(pitch, e));
                      }),
                    ))
                .toList(),
      ),
    );
  }
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
  double offset = 0;
  Offset firstOff;
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
