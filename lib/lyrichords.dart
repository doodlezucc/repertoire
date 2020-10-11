import 'package:flutter/material.dart';

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
    return GestureDetector(
      onDoubleTap: () {
        ctrl.value = TextEditingValue(
            text: ctrl.text.substring(0, ctrl.selection.baseOffset) +
                "  " +
                ctrl.text.substring(ctrl.selection.baseOffset),
            selection: TextSelection(
              baseOffset: ctrl.selection.baseOffset,
              extentOffset: ctrl.selection.extentOffset,
            ));
      },
      child: TextField(
        maxLines: null,
        controller: ctrl,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (s) {
          widget.data.lyrichords = s;
        },
        style: TextStyle(fontFamily: "CourierPrime", fontSize: 13),
      ),
    );
  }
}
