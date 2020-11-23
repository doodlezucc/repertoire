import 'dart:ui';

import 'package:flutter/material.dart';

class TwoLineBundle {
  final TextSpan line1;
  final TextSpan line2;

  TwoLineBundle(this.line1, this.line2);

  TextSpan computeWrap(double width) {
    final TextPainter textPainter = TextPainter(
      text: line1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);

    var range = textPainter.getLineBoundary(TextPosition(offset: 0));
    var rangeLine1But2 =
        textPainter.getLineBoundary(TextPosition(offset: range.end + 1));

    textPainter
      ..text = line2
      ..layout(maxWidth: width);

    var range2 = textPainter.getLineBoundary(TextPosition(offset: 0));

    if (range2.end < range.end || rangeLine1But2.end < 0) {
      range = range2;
    }

    var at = range.end;

    return TextSpan(
      children: [
        cut(line1, at, true),
        cut(line2, at, true),
        cut(line1, at, false),
        cut(line2, at, false),
      ],
    );
  }

  static TextSpan cut(TextSpan ts, int wrap, bool start) {
    var s = ts.text;
    if (s.length <= wrap) {
      if (start)
        return cloneWithText(ts, s + '\n');
      else
        return TextSpan();
    }

    if (start)
      return cloneWithText(ts, s.substring(0, wrap) + '\n');
    else
      return cloneWithText(ts, s.substring(wrap) + '\n');
  }

  static TextSpan cloneWithText(TextSpan src, String s) {
    return TextSpan(text: s, style: src.style);
  }
}
