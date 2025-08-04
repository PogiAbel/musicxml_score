import 'measure.dart';

/// Single notes inside the chord
class Note implements MeasureItem{
  /// The pitch of the note
  Pitch? pitch;
  /// The duration of the note
  int duration;
  /// The type of the note, ie: whole, half, quarter, etc
  String type;
  /// The stem direction of the note
  String stemDirection;
  /// The number of dots after the note
  int dots;
  /// The voice the note is in, ie:1,2,3,4; default:1
  int voice;
  /// The staff the note is in, ie:1,2,3,4; default:1
  int staff;
  /// If the note is a grace note
  Grace? grace;
  /// The accidental of the note
  String? accidental;

  /// A list of [Beam]s the note has
  List<Beam>? beam;
  /// A list of [Lyric] the note has
  List<Lyric>? lyrics;
  /// A list of [Notations] the note has
  List<Notations>? notations;
  /// The note is a cue note
  bool isCue;
  /// The note is in a chord
  bool isChord;
  /// The note is a rest
  bool isRest;
  /// The note is a rest measure
  bool isRestMeasure;

  Note({
    required this.duration,
    required this.type,
    required this.stemDirection,
    required this.dots,
    required this.voice,
    required this.staff,
    this.pitch,
    this.grace,
    this.accidental,
    this.beam,
    this.lyrics,
    this.notations,
    this.isCue = false,
    this.isChord = false,
    this.isRest = false,
    this.isRestMeasure = false
  });

  factory Note.base(){
    return Note(
      pitch: Pitch(step: 'C', octave: 4),
      duration: 4,
      type: 'quarter',
      stemDirection: 'up',
      voice: 1,
      staff: 1,
      dots: 0,
      isRest: false,
      isChord: false,
      isCue: false
    );
  }

  @override
  String toString() {
    return """{Note: ${pitch?.step}${pitch?.octave}
     type: $type
     duration: $duration 
     stemDirection: $stemDirection
     dots: $dots
     voice: $voice
     staff: $staff
     grace: $grace
     accidental: $accidental
     beams: $beam
     lyrics? $lyrics
     notations: $notations
     cue: $isCue
     chord: $isChord
     rest: $isRest}""";
  }

  @override
  MeasureItem copy() {
    return Note(duration: duration,
     type: type,
      stemDirection: stemDirection,
      dots: dots, voice: voice, staff: staff,
      pitch : pitch,
      grace : grace,
      accidental : accidental,
      beam : beam,
      lyrics : lyrics,
      notations : notations,
      isCue : isCue,
      isChord : isChord,
      isRest : isRest,
      isRestMeasure : isRestMeasure);
  }
}

class Pitch{
  String step;
  int octave;
  int alter;

  Pitch({required this.step, required this.octave, this.alter = 0});
}

class Grace{
  bool slash;

  Grace({required this.slash});
}

enum BeamType{
  begin,
  advance,
  end,
  backwardHook,
  forwardHook
}

class Beam{
  BeamType type;
  int id;

  Beam({required this.type, required this.id});

  Beam.fromText({required String text, required this.id}):
    type = switch(text){
      "begin" => BeamType.begin,
      "end" => BeamType.end,
      "continue" => BeamType.advance,
      "backward hook" => BeamType.backwardHook,
      "forward hook" => BeamType.forwardHook,
      _ => BeamType.begin,
    };
  
}

class Lyric{
  String syllabic;
  String text;
  int number;

  Lyric({required this.syllabic, required this.text, required this.number});
}


/// Class all notations should implement
/// 
/// Supproted notations:
/// - Slur
abstract class Notations{}

class Slur extends Notations{
  String type;
  int number;
  String? orientation;

  Slur({required this.type, required this.number, this.orientation});
}