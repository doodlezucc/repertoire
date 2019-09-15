import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repertories/image_to_music.dart';
import 'package:xml/xml.dart';

import 'repertory.dart';

class ScoreDisplay extends StatefulWidget {
  final Song song;

  const ScoreDisplay({Key key, @required this.song}) : super(key: key);

  @override
  _ScoreDisplayState createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<ScoreDisplay> {
  @override
  Widget build(BuildContext context) {
    return Column(
        children: List.from(
            widget.song.scoreProviders.map((sp) => ProviderWidget(
                  provider: sp,
                  onRemove: () {
                    setState(() {
                      widget.song.scoreProviders.remove(sp);
                    });
                  },
                )))
          ..addAll(widget.song.scoreProviders.any((sp) => sp is ImageProvider)
              ? [
                  FlatButton(
                    child: Text("Digitalize"),
                    onPressed: () {
                      requestSheetInterpretation(widget.song);
                    },
                  )
                ]
              : [])
          ..add(Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.image),
                onPressed: () async {
                  File picked =
                      await ImagePicker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    Directory dir = await getApplicationDocumentsDirectory();
                    File copy = await picked
                        .copy(join(dir.path, basename(picked.path)));
                    setState(() {
                      widget.song.scoreProviders.add(ImageProvider(copy));
                    });
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.photo_camera),
                onPressed: () async {
                  File picked =
                      await ImagePicker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() {
                      widget.song.scoreProviders.add(ImageProvider(picked));
                    });
                  }
                },
              )
            ],
          )));
  }
}

class ProviderWidget extends StatelessWidget {
  final ScoreProvider provider;
  final void Function() onRemove;

  const ProviderWidget(
      {Key key, @required this.provider, @required this.onRemove})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        provider.dispose();
        onRemove();
      },
      child: provider.build(context),
    );
  }
}

abstract class ScoreProvider {
  Widget build(BuildContext ctx);

  String _getType();

  void dispose();

  Map<String, dynamic> toJson() => {"type": _getType()};
  static ScoreProvider fromJson(Map<String, dynamic> json) {
    switch (json["type"]) {
      case ImageProvider._TYPENAME:
        return ImageProvider.fromJson(json);
    }
    return null;
  }
}

abstract class _FileScoreProvider extends ScoreProvider {
  File file;
  _FileScoreProvider(this.file);

  @override
  void dispose() {
    file.delete();
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({"file": file.path});

  _FileScoreProvider.fromJson(Map<String, dynamic> json)
      : file = File(json["file"]);
}

class ImageProvider extends _FileScoreProvider {
  static const String _TYPENAME = "image";

  ImageProvider(File file) : super(file);
  ImageProvider.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  @override
  Widget build(BuildContext ctx) {
    return FadeInImage(
        image: FileImage(file), placeholder: AssetImage("assets/loader.gif"));
  }

  @override
  String _getType() {
    return _TYPENAME;
  }
}

class PdfProvider {}

class MusicXmlProvider {}

abstract class Xml {
  Xml.fromX(XmlElement e);
}

class Score {
  final PartList partList;

  Score.xml(XmlDocument musicxml)
      : partList = PartList.fromXML(musicxml.findElements("part-list").first);
}

class PartList {
  List<ScorePart> parts = [];

  PartList({this.parts});

  PartList.fromXML(XmlElement xml)
      : parts = xml.children
            .map((scorePart) => ScorePart.fromX(scorePart))
            .toList();
}

class ScorePart extends Xml {
  String id;
  String partName;
  String partAbbreviation;

  ScorePart.fromX(XmlElement e) : super.fromX(e);
}

class ScoreInstrument extends Xml {
  String id;
  String instrumentName;

  ScoreInstrument.fromX(XmlElement e)
      : id = e.getAttribute("id"),
        instrumentName = e.firstChild.text,
        super.fromX(e);
}
