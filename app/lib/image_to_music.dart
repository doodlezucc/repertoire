import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as i;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DecodeParam {
  final File file;
  final SendPort sendPort;
  DecodeParam(this.file, this.sendPort);
}

class ItMApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Repertory",
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  File file;
  File output;

  void dewit() async {
    ReceivePort receivePort = ReceivePort();

    await Isolate.spawn(
        interpretSheet, DecodeParam(file, receivePort.sendPort));

    // Get the processed image from the isolate.
    i.Image image = await receivePort.first;

    File f = File(join((await getExternalStorageDirectory()).path,
        DateTime.now().millisecondsSinceEpoch.toString() + ".png"));

    await f.writeAsBytes(i.encodePng(image));
    print("done i guess");
    print(f.path);

    setState(() {
      output = f;
    });
  }

  static void interpretSheet(DecodeParam param) {
    print("Interpreting image ${param.file.path}");
    var resized =
        i.copyResize(i.decodeImage(param.file.readAsBytesSync()), width: 500);
    print("resized");
    var adj =
        i.adjustColor(resized, brightness: 1.25, contrast: 3, saturation: 0);
    print("adjusted");
    param.sendPort.send(adj);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("testing stuff")),
      body: ListView(
        children: <Widget>[
          RaisedButton(
            onPressed: () async {
              File img =
                  await ImagePicker.pickImage(source: ImageSource.gallery);
              setState(() {
                this.file = img;
              });
            },
            child: Text("pick image"),
          ),
          RaisedButton(
            onPressed: () async {
              dewit();
            },
            child: Text("process, please"),
          ),
          (output != null
              ? Image.file(
                  output,
                )
              : Container())
        ],
      ),
    );
  }
}
