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
    var rangeLine2But2 =
        textPainter.getLineBoundary(TextPosition(offset: range2.end + 1));

    if (rangeLine1But2.end + rangeLine2But2.end == -2) {
      // nothing wraps
      return TextSpan(
          children: [cloneWithNewline(line1), cloneWithNewline(line2)]);
    }

    // line1 or line2 wraps

    if (rangeLine2But2.end >= 0 &&
        (rangeLine1But2.end < 0 // line2 wraps, line1 doesn't
            ||
            range2.end < range.end)) // both wrap, line2 at an earlier point
      range = range2;

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
    var s = ts.text!;
    if (s.length <= wrap) {
      if (start)
        return cloneWithTextAndNewline(ts, s);
      else
        return TextSpan();
    }

    if (start)
      return cloneWithTextAndNewline(ts, s.substring(0, wrap));
    else
      return cloneWithTextAndNewline(ts, s.substring(wrap));
  }

  static TextSpan cloneWithNewline(TextSpan ts) {
    return cloneWithTextAndNewline(ts, ts.text!);
  }

  static TextSpan cloneWithTextAndNewline(TextSpan src, String s) {
    return TextSpan(text: s + '\n', style: src.style);
  }
}
