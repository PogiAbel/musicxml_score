import 'package:flutter/material.dart';
import 'package:musicxml_score/musicxml_score.dart';


void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusicXML Score Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  MainPage({super.key});

  ScoreParser scoreParser = ScoreParser();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MusicXML Score Viewer'),
      ),
      body: FutureBuilder(
        future: scoreParser.parseMxl('assets/test2.mxl'),
        builder: (BuildContext context, AsyncSnapshot<Score> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            LayoutGenerator generator = LayoutGenerator(
              score: snapshot.data!,
            );
            ScoreObject score = generator.generateScore();
            return ScoreCanvas(size: const Size(800,800), scoreObject: score);
          }
        },
    )
  );
  }
}