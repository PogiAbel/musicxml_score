import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();

}

class _MainPageState extends State<MainPage> {

  static const List<String> mxlFiles = [
    "assets/test1.mxl",
    "assets/test2.mxl",
    "assets/test3.mxl",
    "assets/test4.mxl",
    "assets/test5.mxl",
  ];
  int currentFileIndex = 0;

  Future<Score> loadScore() async {
    ByteData data = await rootBundle.load(mxlFiles[currentFileIndex]);
    final bytes = data.buffer.asUint8List();
    Score score = await ScoreParser().parseMxlBytes(bytes);
    return score;
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('MusicXML Score Viewer'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentFileIndex = ++currentFileIndex % mxlFiles.length; 
                  });
                },
                child: const Text('Previous'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentFileIndex = --currentFileIndex % mxlFiles.length; 
                  });
                },
                child: const Text('Next'),
              ),
              Text('File: ${mxlFiles[currentFileIndex]}'),
            ],
          ),
          Expanded(
            child: FutureBuilder(
              // future: ScoreParser().parseMxl(mxlFiles[currentFileIndex]),
              future: loadScore(),
              builder: (BuildContext context, AsyncSnapshot<Score> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  double maxWidth = MediaQuery.of(context).size.width;
                  LayoutGenerator generator = LayoutGenerator(
                    score: snapshot.data!,
                    maxWidth: maxWidth - 100
                  );
                  ScoreObject score = generator.generateScore();
                  return ScoreCanvas(size: Size(maxWidth,800), scoreObject: score);
                }
              },
                ),
          ),
        ],
      )
  );
  }
}