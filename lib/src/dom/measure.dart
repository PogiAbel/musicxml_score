import '../generated/glyph-definitions.dart';
import 'note.dart';
import '../extension/list_extension.dart';

/// Abstract class for items in measure whose order matters i.e. notes, rests, barlines, backups etc.
abstract class MeasureItem{
  /// Creates a deep copy of the object
  MeasureItem copy();
}

/// [Measure] contains notes and relavant informations
class Measure{
  /// The attributes of the measure
  Attributes? attributes;
  /// The notes in the measure
  List<MeasureItem> items = [];
  /// The number of the measure
  int number;

  Measure({this.attributes,required this.number, required this.items});

  Measure.from(Measure measure)
      : attributes = measure.attributes,
        number = measure.number,
        items = measure.items.map((e) => e.copy()).toList();

  @override
  String toString() {
    return "{Measure:\n   number : $number \n   Notes: ${items.length}\n   Attributes: $attributes}";
  }

  /// Get the shortest duration from notes in the measure
  int get shortestNote =>items.fold(100, (previousValue, element) {
      if(element is Note){
        return element.duration < previousValue ? element.duration : previousValue;
      }
      return previousValue;
    });
}

class Attributes{
  /// The number of divisions in the measure
  int? divisions;
  /// The key of the measure
  MusicKey? key;
  /// The time signature of the measure
  Time? time;
  /// Number of staves
  int? staves;
  /// The clefs of the measure
  List<Clef>? clefs;

  Attributes({this.divisions, this.key, this.time, this.clefs, this.staves});

  @override
  String toString() {
    return "{Attributes: Divisions: $divisions, Key: $key, Time: $time, Staves: $staves Clefs: ${clefs?.length}}";
  }

  /// Update the attribute values
  Attributes update(Attributes newAttributes){
    return Attributes(
      divisions: newAttributes.divisions ?? divisions,
      key: newAttributes.key ?? key,
      time: newAttributes.time ?? time,
      staves: newAttributes.staves ?? staves,
      clefs: clefs!.update(newAttributes.clefs)
    );
  }
}
extension ClefUpdate on List<Clef>{
  update(List<Clef>? newValues){
    if(newValues == null) return this;
    for(Clef c in this){
      Clef? newClef = newValues.firstWhereOrNull((e) => e.number == c.number);
      if(newClef != null) c = newClef;
    }
    return this;
  }
}

/// Contains information about the key
class MusicKey{
  /// The number of fifths in the key signature
  int fifths;

  MusicKey({required this.fifths});

  /// Default flat positions in the g key, 0 is the top line
  static List<double> flatDefault = [2, 0.5, 2.5, 1, 3, 1.5, 3.5];

  /// Default sharp positions in the g key, 0 is the top line
  static List<double> sharpDefault = [0, 1.5, -0.5, 1, 2.5, 0.5, 2];

  /// Returns a list containing the position of each accidental, 0 is the top line
  List<double> accidentalList(Glyph accidental, Glyph clef){
    switch(accidental){
      case Glyph.accidentalSharp:
        return sharpPosition(clef);
      case Glyph.accidentalFlat:
        return flatPosition(clef);
      default:
        return [];
    }
  }

  /// Transfare sharp positions based on clef
  List<double> sharpPosition(Glyph clef){
    switch(clef){
      case Glyph.gClef:
        return sharpDefault;
      case Glyph.fClef:
        return sharpDefault.map((e) => e + 1).toList();
      case Glyph.cClef:
        return sharpDefault.map((e) => e + 0.5).toList();
      default:
        return sharpDefault;
    }
  }

/// Transfare flat positions based on clef
  List<double> flatPosition(Glyph clef){
    switch(clef){
      case Glyph.gClef:
        return flatDefault;
      case Glyph.fClef:
        return flatDefault.map((e) => e + 1).toList();
      case Glyph.cClef:
        return flatDefault.map((e) => e + 0.5).toList();
      default:
        return flatDefault;
    }
  }
}


/// Contains information about the time signature
class Time{
  /// The number of beats in a measure
  int beats;
  /// The type of note that gets the beat
  int beatType;
  Glyph beatGlyph;
  Glyph timeGlyph;

  Time({required this.beats, required this.beatType})
  : beatGlyph = Glyph.values.firstWhere((element) => element.toString() == "Glyph.timeSig$beats"),
    timeGlyph = Glyph.values.firstWhere((element) => element.toString() == "Glyph.timeSig$beatType");
}

/// Contains information about the clef
class Clef{
  /// The sign of the clef
  String sign;
  /// The line of the clef
  int line;
  /// The glyph of the clef
  Glyph glyph;
  /// The number of the staff the clef is in
  int number;

  Clef({required this.sign, required this.line, required this.number})
      : glyph = sign == "G" ? Glyph.gClef : sign == "F" ? Glyph.fClef : Glyph.cClef;

  /// Get the note name on the middle line
  String get noteName {
    String noteName;

    switch(glyph){
      case Glyph.gClef:
        noteName = "B4";
        break;
      case Glyph.fClef:
        noteName = "D3";
        break;
      case Glyph.cClef:
        noteName = "C4";
        break;
      default:
        throw "Clef type not found";
    }

    return noteName;
  } 
}

class Barline implements MeasureItem{
  /// The type of the barline
  String type;
  /// The location of the barline
  String location;
  /// Repeat
  String? repeatType;

  Barline({required this.type, required this.location, this.repeatType});

  @override
  Barline copy(){
    return Barline(type:type, location: location, repeatType: repeatType);
  }
}

class Backup implements MeasureItem{
  /// The duration of the backup
  int duration;

  Backup({required this.duration});

  @override
  Backup copy(){
    return Backup(duration: duration);
  }
}

class Harmony implements MeasureItem{
  String root;
  int? rootAlter;
  String kind;
  int? dergree;
  int? degreeAlter;
  String? degreeType;
  String? bassStep;

  Harmony({required this.root, this.rootAlter, required this.kind, this.dergree, this.degreeAlter, this.degreeType, this.bassStep});

  @override
  Harmony copy(){
    return Harmony(
      root: root,
      rootAlter: rootAlter,
      kind: kind,
      dergree: dergree,
      degreeAlter: degreeAlter,
      degreeType: degreeType,
      bassStep: bassStep
    );
  }
}