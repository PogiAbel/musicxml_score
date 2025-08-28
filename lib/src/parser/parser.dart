import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

import '../dom/measure.dart';
import '../dom/note.dart';
import '../dom/part.dart';
import '../dom/score.dart';

class ScoreParser{
  static ScoreParser? _instance;

  factory ScoreParser(){
    _instance ??= ScoreParser._internal();
    return _instance!;
  }

  ScoreParser._internal();

  /// Parses a MusicXML file and returns a [Score] object
  Future<Score> parseMxl(String path) async {
    XmlDocument musicXmlDocument = await unzipMxl(path);
    return parseDocument(musicXmlDocument);
  }

  Future<Score> emptyScore() async {
    XmlDocument doc = await unzipMxl("./assets/empty.mxl");
    return parseDocument(doc);
  }

  /// Unzips Mxl files and returns the last xml file as an [XmlDocument]
  Future<XmlDocument> unzipMxl(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final xmlFile = archive.files.last;
    XmlDocument musicXmlDocument = XmlDocument.parse(utf8.decode(xmlFile.content));
    return musicXmlDocument;
  }

  Future<Score> parseMxlBytes(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final xmlFile = archive.files.last;
    XmlDocument musicXmlDocument = XmlDocument.parse(utf8.decode(xmlFile.content));
    return parseDocument(musicXmlDocument);
  }

  /// Parses the xml string and returns an [XmlDocument]
  XmlDocument parseXmlString(String xmlString){
    return XmlDocument.parse(xmlString);
  }

  /// Parses the xml file and returns an [XmlDocument]
  Future<XmlDocument> parseXmlFile(String path) async {
    final xmlString = await File(path).readAsString();
    return XmlDocument.parse(xmlString);
  }

  /// Parses the [XmlDocument] into a [Score]
  Score parseDocument(XmlDocument xmlDocument){
    String title = xmlDocument.xpathEvaluate('score-partwise/work/work-title').string;
    String composer = xmlDocument.xpathEvaluate('score-partwise/identification/creator').string;
    List<Part> parts = xmlDocument.xpath("score-partwise/part").map((partNode) => _parsePartXml(partNode)).toList();
    return Score(title: title, composer: composer, parts: parts);
  }

  Part _parsePartXml(XmlNode partXml){
    String id = partXml.xpathEvaluate("@id").string;
    List<Measure> measures = partXml.xpath("measure").map((measureNode) => _parseMeasureXml(measureNode)).toList();
    return Part(id: id, measures: measures);
  }

  /// Parses a measure xml node into a [Measure]
  Measure _parseMeasureXml(XmlNode measureXml){
    int number = measureXml.xpathEvaluate("@number").number.toInt();
    bool implicit = measureXml.xpathEvaluate("@implicit").boolean;
    Attributes? attributes;

    List<MeasureItem> items = [];
    measureXml.children.whereType<XmlElement>().forEach((xmlNode) {
      switch(xmlNode.localName){
        case "note":
          if(xmlNode.xpath("grace").isNotEmpty) break;
          items.add(_parseNoteXml(xmlNode));
          break;
        case "barline":
        items.add(_parseBarline(xmlNode));
          break;
        case "backup":
        items.add(_parseBackup(xmlNode));
          break;
        case "harmony":
        items.add(_parseHarmony(xmlNode));
          break;
        case "attributes":
          attributes = _parseAttribute(xmlNode);
          break;
        default:
          break;
      }
    });

    return Measure(attributes: attributes,number: number, items: items, implicit: implicit);
  }

  /// Parses a note xml node into a [Note]
  Note _parseNoteXml(XmlNode noteXml){
    Pitch? pitch = noteXml.xpath("pitch").isNotEmpty ? Pitch(step: noteXml.xpathEvaluate("pitch/step").string,
                        octave: noteXml.xpathEvaluate("pitch/octave").number.toInt(),
                        alter: noteXml.xpathEvaluate("pitch/alter").string.isNotEmpty ? noteXml.xpathEvaluate("pitch/alter").number.toInt() : 0) : null;
    int duration = noteXml.xpathEvaluate("duration").number.toInt();
    String type = noteXml.xpathEvaluate("type").string;
    type = type == "eighth" ? "8th" : type;
    String stemDirection = noteXml.xpathEvaluate("stem").string;
    int dots = noteXml.xpath("dot").length;
    int voice = noteXml.xpathEvaluate("voice").string.isNotEmpty ? noteXml.xpathEvaluate("voice").number.toInt() : 1;
    int staff = noteXml.xpathEvaluate("staff").string.isNotEmpty ? noteXml.xpathEvaluate("staff").number.toInt() : 1;
    Grace? grace = noteXml.xpath("grace").isNotEmpty ? Grace(slash: noteXml.xpathEvaluate("grace/slash").string == "yes") : null;
    String? accidental = noteXml.xpathEvaluate("accidental").string.isNotEmpty ? noteXml.xpathEvaluate("accidental").string : null;
    if (accidental != null && accidental == "double-sharp") accidental = "DoubleSharp";
    
    List<Lyric>? lyrics = noteXml.xpath("lyric").isEmpty ? null : noteXml.xpath("lyric").map((lyricNode) => Lyric(syllabic: lyricNode.xpathEvaluate("syllabic").string, text: lyricNode.xpathEvaluate("text").string, number: int.parse(lyricNode.getAttribute("number") ?? "1"))).toList();
    List<Beam>? beams = noteXml.xpath("beam").isEmpty ? null : noteXml.xpath("beam").map((beamNode) => Beam.fromText(text: beamNode.innerText, id: int.parse(beamNode.getAttribute("number") ?? "1"))).toList();

    bool isCue = noteXml.xpath("cue").isNotEmpty;
    bool isChord = noteXml.xpath("chord").isNotEmpty;
    bool isRest = noteXml.xpath("rest").isNotEmpty;
    bool restMeasure = false;
    if(isRest){
      restMeasure = noteXml.xpath("rest[@*]").isNotEmpty;
    }

    return Note(pitch: pitch, duration: duration, type: type, stemDirection: stemDirection, dots: dots, voice: voice, staff: staff, grace: grace, accidental: accidental, lyrics: lyrics, beam: beams, isCue: isCue, isChord: isChord, isRest: isRest, isRestMeasure: restMeasure);
  }

  /// Parses an attribute xml node into an [Attributes]
  Attributes _parseAttribute(XmlNode attributeNode){
    int? divisions = attributeNode.xpath("divisions").isNotEmpty ? attributeNode.xpathEvaluate("divisions").number.toInt() : null;
    MusicKey? key = attributeNode.xpath("key").isNotEmpty ? MusicKey(fifths: attributeNode.xpathEvaluate("key/fifths").number.toInt()) : null;
    Time? time = attributeNode.xpath("time").isNotEmpty ? Time(beats: attributeNode.xpathEvaluate("time/beats").number.toInt(), beatType: attributeNode.xpathEvaluate("time/beat-type").number.toInt()) : null;
    int? staves = attributeNode.xpath("staves").isNotEmpty ? attributeNode.xpathEvaluate("staves").number.toInt() : null;
    List<Clef>? clefs = attributeNode.xpath("clef").isNotEmpty ? attributeNode.xpath("clef").map((clefNode) => Clef(sign: clefNode.xpathEvaluate("sign").string, line: clefNode.xpathEvaluate("line").number.toInt(), number: clefNode.xpath("@number").isEmpty ? 1 : clefNode.xpathEvaluate("@number").number.toInt())).toList() : null;

    return Attributes(divisions: divisions, key: key, time: time,staves: staves, clefs: clefs);
  }
  
  /// Parses a barline xml node into a [Barline]
  MeasureItem _parseBarline(XmlElement xmlNode) {
    String location = xmlNode.xpathEvaluate("@location").string;
    String type = xmlNode.xpathEvaluate("bar-style").string;
    String? repeat = xmlNode.xpath("repeat").isNotEmpty ? xmlNode.xpathEvaluate("repeat/@direction").string : null;
    return Barline(type: type, location: location, repeatType: repeat);
  }
  
  MeasureItem _parseHarmony(XmlElement xmlNode) {
    String root = xmlNode.xpathEvaluate("root/root-step").string;
    int? rootAlter = xmlNode.xpath("root/root-alter").isNotEmpty ? xmlNode.xpathEvaluate("root/root-alter").number.toInt() : null;
    String kind = xmlNode.xpathEvaluate("kind").string;
    int? degree = xmlNode.xpath("degree/degree-value").isNotEmpty ? xmlNode.xpathEvaluate("degree/degree-value").number.toInt() : null;
    int? degreeAlter = xmlNode.xpath("degree/degree-alter").isNotEmpty ? xmlNode.xpathEvaluate("degree/degree-alter").number.toInt() : null;
    String? degreeKind = xmlNode.xpath("degree/degree-type").isNotEmpty ? xmlNode.xpathEvaluate("degree/degree-type").string : null;
    String? bassStep = xmlNode.xpath("bass/bass-step").isNotEmpty ? xmlNode.xpathEvaluate("bass/bass-step").string : null;
    return Harmony(root: root, rootAlter: rootAlter, kind: kind, dergree: degree, degreeAlter: degreeAlter, degreeType: degreeKind, bassStep: bassStep);
  }

  MeasureItem _parseBackup(XmlElement xmlNode) {
    int duration = xmlNode.xpathEvaluate("duration").number.toInt();
    return Backup(duration: duration);
  }
}