import 'package:flutter/material.dart';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';
import 'package:pitchupdart/pitch_result.dart';

const frameLength = 3000;
const sampleRate = 44100;
const bufferRange = 32768;

class TunerPage extends StatefulWidget {
  const TunerPage({Key? key}) : super(key: key);

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  static const style = TextStyle(fontSize: 24);
  final buffer = List<double>.filled(frameLength, 0);
  final pitchDetector = PitchDetector(sampleRate.toDouble(), frameLength);
  final pitchup = PitchHandler(InstrumentType.guitar);
  final VoiceProcessor processor =
      VoiceProcessor.getVoiceProcessor(frameLength, sampleRate);

  void Function()? removeListener;
  bool switching = false;
  bool get recording => processor.isRecording;
  PitchResult? result;
  double cents = 0;

  @override
  void initState() {
    super.initState();
    toggleRecording();
  }

  @override
  void dispose() {
    stopRecording();
    super.dispose();
  }

  void removeListeners() {
    if (removeListener != null) removeListener!();
  }

  void toggleRecording() async {
    setState(() => switching = true);
    await (recording ? stopRecording() : startRecording());
    setState(() => switching = false);
  }

  Future<void> startRecording() async {
    removeListener = processor.addListener(processAudioBuffer);

    if (await processor.hasRecordAudioPermission() ?? false) {
      await processor.start();
    } else {
      print('No permission!');
    }
  }

  Future<void> stopRecording() async {
    removeListeners();
    await processor.stop();
  }

  void processAudioBuffer(dynamic event) {
    setState(() {
      List<Object?> data = event; // list of [int]

      for (int i = 0; i < frameLength; i++) {
        var v = data[i] as int;
        buffer[i] = v / bufferRange;
      }
      var pitch = pitchDetector.getPitch(buffer);
      result = pitchup.handlePitch(pitch.pitch);
      cents = cents + (result!.diffCents - cents) * 0.4;
    });
  }

  String offText() {
    var c = -cents.round();
    var s = '$c';
    if (c >= 0) {
      s = '+$s';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuner'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(result != null ? '${result!.note}' : '', style: style),
              Container(
                width: double.infinity,
                height: 300,
                child: CustomPaint(
                  painter: TunerPainter(buffer),
                ),
              ),
              Text(offText(), style: style),
              // TextButton.icon(
              //   icon: Icon(Icons.mic),
              //   label: Text(recording ? 'Stop recording' : 'Record'),
              //   onPressed: switching ? null : toggleRecording,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class TunerPainter extends CustomPainter {
  static final linePaint = Paint()..strokeWidth = 2;
  final List<double> buffer;

  TunerPainter(this.buffer);

  @override
  void paint(Canvas canvas, Size size) {
    Offset? prev;

    var steps = size.width ~/ 2;
    // var max = 0.0;
    for (var i = 0; i < steps; i++) {
      var index = buffer.length * i ~/ steps;
      var progress = (i / (steps - 1));
      var x = progress * size.width;

      var v = buffer[index];
      // var absV = v.abs();
      // if (absV > max) max = absV;

      var mid = (0.5 - (progress - 0.5).abs()) * 2;
      v *= mid;

      var y = (0.5 + v) * size.height;
      var p = Offset(x, y);

      if (i != 0) {
        canvas.drawLine(prev!, p, linePaint);
      }

      prev = p;
    }
  }

  @override
  bool shouldRepaint(covariant TunerPainter oldDelegate) {
    return true;
  }
}
