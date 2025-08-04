import 'measure.dart';

/// [Part] contains measures and relavant informations
class Part{

  /// List of measures in the part
  List<Measure> measures = [];
  /// The id of the part
  String id;

  Part({required this.id, required this.measures});
}