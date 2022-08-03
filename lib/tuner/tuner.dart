import 'package:flutter/material.dart';

class TunerPage extends StatelessWidget {
  const TunerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuner'),
      ),
      body: Column(
        children: [
          Text('6 String Default'),
        ],
      ),
    );
  }
}
