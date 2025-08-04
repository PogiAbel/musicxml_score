import 'part.dart';

/// Score class that represents a music score
/// contains all the necesseary information to generate the [ScoreObject]
class Score{
  final String title;
  final String composer;
  /// List of parts in the score
  List<Part> parts = [];

  Score({required this.title, required this.composer, required this.parts});

  @override
  String toString() {
    return "{Score: Title: $title, Composer: $composer, Parts: ${parts.length}}";
  }
}
