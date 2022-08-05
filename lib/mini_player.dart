import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class MiniPlayer extends StatefulWidget {
  final AudioPlayer player;
  final String source;

  const MiniPlayer({Key? key, required this.player, required this.source})
      : super(key: key);

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Duration? position;
  Duration? duration;
  bool get isPlaying => widget.player.state == PlayerState.playing;
  final List<StreamSubscription> subscriptions = [];
  String get title => basenameWithoutExtension(widget.source);
  double? progressOverride;

  @override
  void initState() {
    super.initState();

    subscriptions.addAll([
      widget.player.onDurationChanged
          .listen((d) => setState(() => duration = d)),
      widget.player.onPositionChanged
          .listen((d) => setState(() => position = d)),
      widget.player.onPlayerStateChanged.listen((_) => setState(() {})),
      widget.player.onPlayerComplete.listen((d) async {
        await widget.player.stop();
        position = null;
        setState(() {});
      }),
    ]);

    File(widget.source)
        .readAsBytes()
        .then((bytes) => widget.player.setSourceBytes(bytes));
  }

  @override
  void dispose() {
    subscriptions.forEach((sub) => sub.cancel());
    super.dispose();
  }

  static String timeString(Duration d) {
    var min = d.inMinutes;
    var sec = d.inSeconds % 60;
    var secString = '$sec'.padLeft(2, '0');

    return '$min:$secString';
  }

  static Duration scaleDuration(Duration duration, double x) {
    return Duration(milliseconds: (duration.inMilliseconds * x).toInt());
  }

  @override
  Widget build(BuildContext context) {
    Duration? overridePosition = position;

    void updateOverride() {
      overridePosition = scaleDuration(duration!, progressOverride!);
    }

    if (duration != null && progressOverride != null) {
      updateOverride();
    }

    var text = title;
    if (duration != null) {
      text = '$text (${timeString(duration!)})';
      if (overridePosition != null) {
        text = '$text - ${timeString(overridePosition!)}';
      }
    }

    var value = 0.0;
    if (duration != null) {
      value =
          (overridePosition?.inMilliseconds ?? 0) / duration!.inMilliseconds;
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 16),
              Expanded(child: Text(text)),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: duration != null
                    ? (isPlaying ? widget.player.pause : widget.player.resume)
                    : null,
              ),
            ],
          ),
          Slider(
            value: value,
            onChanged: (v) => setState(() {
              progressOverride = v;
              updateOverride();
            }),
            onChangeEnd: (v) {
              progressOverride = null;
              position = overridePosition;
              widget.player.seek(overridePosition!);
            },
          ),
        ],
      ),
    );
  }
}
