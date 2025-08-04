import 'package:flutter/material.dart';
import 'drawable.dart';

import '../dom/score.dart';

/// [ScoreObject] class that represents a music score objects that would be drawn
/// 
/// A [Score] would be parsed into a [ScoreObject]
/// 
/// Contains all the necessary information and objects to draw the score
class ScoreObject{
  final List<Drawable> drawables;
  bool showBoundingBox = false;

  ScoreObject({required this.drawables, this.showBoundingBox = false});

  void draw(Canvas canvas){
    for (var item in drawables){
      item.draw(canvas);
    }
    if(showBoundingBox){
      for(var item in drawables){
        item.drawBbox(canvas, exclude: [DrawableType.line]);
      }
    }
  }
}