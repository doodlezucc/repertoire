import 'package:flutter/material.dart';

import '../music_theory.dart';
import '../repertory.dart';
import 'text_size.dart';

class LyrichordsDisplayField extends StatefulWidget {
  final SongData data;
  final TextStyle style;

  const LyrichordsDisplayField(
      {Key key, @required this.data, @required this.style})
      : super(key: key);

  @override
  _LyrichordsDisplayFieldState createState() => _LyrichordsDisplayFieldState();
}

class _LyrichordsDisplayFieldState extends State<LyrichordsDisplayField> {
  @override
  void initState() {
    super.initState();
  }

  TextStyle get baseStyle => Theme.of(context).textTheme.overline;

  TextSpan chordLine(String line) {
    return TextSpan(text: line, style: baseStyle.copyWith(color: Colors.red));
  }

  TextSpan textLine(String line) {
    return TextSpan(text: line, style: baseStyle);
  }

  TextSpan getWrappedLyrichords() {
    var watch = Stopwatch()..start();

    var bundles = <TextSpan>[];
    var srcLines = widget.data.lyrichords.split('\n');

    var width = MediaQuery.of(context).size.width - 16;

    for (var i = 0; i < srcLines.length; i++) {
      var line = srcLines[i];

      if (containsChords(line)) {
        if (i + 1 == srcLines.length ||
            srcLines[i + 1].isEmpty ||
            containsChords(srcLines[i + 1])) {
          bundles.add(chordLine(line + '\n'));
        } else {
          bundles.add(TwoLineBundle(chordLine(line), textLine(srcLines[i + 1]))
              .computeWrap(width));
          i++;
        }
      } else {
        bundles.add(textLine(line + '\n'));
      }
    }

    print(watch.elapsed.inMilliseconds);

    return TextSpan(children: bundles);
  }

  @override
  Widget build(BuildContext context) {
    //print(getWrappedLyrichords().toStringDeep());
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text.rich(
        getWrappedLyrichords(),
        softWrap: true,
      ),
    );
  }
}
