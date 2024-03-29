import 'package:flutter/material.dart';

import 'repertory.dart';
import 'song_edit_page.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final void Function() onDelete;
  final void Function() onEdited;

  const SongListTile({
    Key? key,
    required this.song,
    required this.onDelete,
    required this.onEdited,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(song.data.description),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          song.remove();
          onDelete();
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => SongEditPage(song: song)),
        ).then((v) {
          onEdited();
        });
      },
    );
  }
}
