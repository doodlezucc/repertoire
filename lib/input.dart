import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'music_theory.dart';

class ChordField extends StatelessWidget {
  final Chord value;
  final void Function(Chord val) onChanged;

  ChordField({@required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      minWidth: 0,
      color: Colors.grey[200],
      onPressed: () async {
        var chord = await showInputChord(context: context, init: value);
        if (chord != null) {
          onChanged(chord);
        }
      },
      child: Text(value.nameAbbreviated),
    );
  }
}

class KeyScaleField extends StatelessWidget {
  final KeyScale value;
  final void Function(KeyScale val) onChanged;

  KeyScaleField({@required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: () async {
        var keyscale = await showInputKeyScale(context: context, init: value);
        if (keyscale != null) {
          onChanged(keyscale);
        }
      },
      child: Text(value.name),
    );
  }
}

class ClampedPitchField extends StatelessWidget {
  final ClampedPitch value;
  final void Function(ClampedPitch val) onChanged;

  ClampedPitchField({@required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: () async {
        var key = await showInputClampedPitch(context: context, init: value);
        if (key != null) {
          onChanged(key);
        }
      },
      child: Text(value.name),
    );
  }
}

Future<Chord> showInputChord(
    {@required BuildContext context, Chord init}) async {
  if (init == null) {
    init = Chord(ClampedPitch.c(), ChordType.Major);
  }
  return await showDialog(
      context: context,
      builder: (ctx) {
        DialogClampedPitch pitch = DialogClampedPitch(init: init.root);
        ChordType type = init.type;

        return AlertDialog(
          title: Text("Enter chord"),
          content: StatefulBuilder(builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                pitch,
                DropdownButton(
                  items: ChordType.values
                      .map((sc) => DropdownMenuItem(
                            child: Text(sc.name),
                            value: sc,
                          ))
                      .toList(growable: false),
                  onChanged: (v) {
                    setState(() {
                      type = v;
                    });
                  },
                  value: type,
                ),
              ],
            );
          }),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(ctx, Chord(pitch.value, type));
              },
            )
          ],
        );
      });
}

Future<KeyScale> showInputKeyScale(
    {@required BuildContext context, KeyScale init}) async {
  if (init == null) {
    init = KeyScale.cMajor();
  }
  return await showDialog(
      context: context,
      builder: (ctx) {
        DialogClampedPitch pitch = DialogClampedPitch(init: init.tonic);
        Scale scale = init.scale;

        return AlertDialog(
          title: Text("Enter key"),
          content: StatefulBuilder(builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                pitch,
                DropdownButton(
                  items: Scale.values
                      .map((sc) => DropdownMenuItem(
                            child: Text(sc.name),
                            value: sc,
                          ))
                      .toList(growable: false),
                  onChanged: (v) {
                    setState(() {
                      scale = v;
                    });
                  },
                  value: scale,
                ),
              ],
            );
          }),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(ctx, KeyScale(pitch.value, scale));
              },
            )
          ],
        );
      });
}

Future<ClampedPitch> showInputClampedPitch(
    {@required BuildContext context, ClampedPitch init}) async {
  if (init == null) {
    init = ClampedPitch.c();
  }
  DialogClampedPitch dcp = DialogClampedPitch(init: init);
  return await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Enter key"),
          content: dcp,
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(ctx, dcp.value);
              },
            )
          ],
        );
      });
}

class DialogClampedPitch extends StatefulWidget {
  final ClampedPitch value;

  DialogClampedPitch({ClampedPitch init})
      : value = init != null
            ? ClampedPitch(init.whiteIndex, init.modification)
            : ClampedPitch.c();

  @override
  _DialogClampedPitchState createState() => _DialogClampedPitchState();
}

class _DialogClampedPitchState extends State<DialogClampedPitch> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 100,
          width: 100,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(child: Container()),
                  Divider(),
                  Expanded(child: Container()),
                  Divider(),
                  Expanded(child: Container()),
                ],
              ),
              ListWheelScrollView.useDelegate(
                childDelegate: ListWheelChildLoopingListDelegate(
                    children: ["C", "B", "A", "G", "F", "E", "D"]
                        .map((s) => Center(child: Text(s)))
                        .toList(growable: false)),
                itemExtent: 32,
                onSelectedItemChanged: (i) {
                  widget.value.whiteIndex = (7 - i) % 7;
                },
                diameterRatio: 1.5,
                squeeze: 1.0,
                physics: FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(
                    initialItem: (7 - widget.value.whiteIndex) % 7),
                magnification: 1.0,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 10,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            buildButton("#", Modification.SHARP),
            buildButton("b", Modification.FLAT)
          ],
        )
      ],
    );
  }

  Widget buildButton(String symbol, Modification m) {
    return MaterialButton(
      minWidth: 0,
      child: Text(symbol),
      onPressed: () {
        setState(() {
          widget.value.modification =
              widget.value.modification == m ? Modification.NONE : m;
        });
      },
      color: widget.value.modification == m ? Colors.blueGrey : Colors.white,
    );
  }
}
