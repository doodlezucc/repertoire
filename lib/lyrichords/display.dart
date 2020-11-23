import 'package:flutter/material.dart';

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

  TextSpan getWrappedLyrichords() {
    var watch = Stopwatch()..start();
    var style = Theme.of(context).textTheme.overline;
    //var line1 = 'Em                A                  C               D';
    //var line2 = 'line which is pretty goddamn long oh boi what is goin';

    var bundles = <TextSpan>[];
    var srcLines = widget.data.lyrichords.split('\n');

    var width = MediaQuery.of(context).size.width - 16;

    for (var i = 0; i < srcLines.length; i += 2) {
      var span1 = TextSpan(
          text: srcLines[i], style: style.copyWith(color: Colors.blue));

      if (srcLines.length == i + 1) {
        bundles.add(span1);
      } else {
        bundles.add(TwoLineBundle(
          span1,
          TextSpan(
            text: srcLines[i + 1],
            style: style,
          ),
        ).computeWrap(width));
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
        softWrap: false,
      ),
    );
  }
}
