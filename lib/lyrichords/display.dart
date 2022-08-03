import 'dart:math';

import 'package:flutter/material.dart';

import '../music_theory.dart';
import '../repertory.dart';
import 'text_size.dart';

class LyrichordsDisplayField extends StatefulWidget {
  final SongData data;
  final TextStyle style;

  const LyrichordsDisplayField(
      {Key? key, required this.data, required this.style})
      : super(key: key);

  @override
  _LyrichordsDisplayFieldState createState() => _LyrichordsDisplayFieldState();
}

class _LyrichordsDisplayFieldState extends State<LyrichordsDisplayField> {
  @override
  void initState() {
    super.initState();
  }

  TextStyle get baseStyle => Theme.of(context).textTheme.overline!;

  TextSpan chordLine(String line, [String suffix = '']) {
    var symbols = RegExp(r'\S+').allMatches(line);

    var l = line;
    if (symbols.isNotEmpty) {
      var off = 0;

      void replaceChord(int spaces, RegExpMatch match) {
        l += ' ' * max(1, spaces + off);

        var chord = match.group(0)!;
        var replacement = transposeSymbol(chord, widget.data.transpose);

        l += replacement;

        off = chord.length - replacement.length;
      }

      l = '';

      replaceChord(symbols.first.start, symbols.first);

      for (var i = 1; i < symbols.length; i++) {
        var match = symbols.elementAt(i);
        var spaces = match.start - symbols.elementAt(i - 1).end;
        replaceChord(spaces, match);
      }
    }

    return TextSpan(
      text: l + suffix,
      style: baseStyle.copyWith(color: Colors.red),
    );
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

      if (isChordLine(line)) {
        if (i + 1 == srcLines.length ||
            srcLines[i + 1].isEmpty ||
            isChordLine(srcLines[i + 1])) {
          bundles.add(chordLine(line, '\n'));
        } else {
          bundles.add(TwoLineBundle(chordLine(line), textLine(srcLines[i + 1]))
              .computeWrap(width));
          i++;
        }
      } else {
        bundles.add(textLine(line + '\n'));
      }
    }

    print('Displayed lyrichords in ${watch.elapsed.inMilliseconds}ms');

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
