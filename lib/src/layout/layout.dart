import 'package:flutter/material.dart';

import '../dom/measure.dart';
import '../dom/score.dart';
import '../renderer/drawable.dart';
import '../renderer/score_object.dart';

import 'music_context.dart';
import 'system_layout.dart';

/// This class generates the drawable objects
/// 
/// It calculates the layout of the whole score
class LayoutGenerator{
  final Score score;
  GlobalContext gc = GlobalContext();
  bool colorPart;
  double maxWidth;
  
  late double minWidth;

  LayoutGenerator({required this.score, this.colorPart = false, this.maxWidth = 900});

  ScoreObject generateScore(){

    List<SystemLayout> systems = [];
    List<Drawable> drawables = [];

    gc.systemWidth = maxWidth - 100;
    gc.currentAttributes = List.generate(score.parts.length, (index) => score.parts[index].measures.first.attributes!);

    for(var attribute in gc.currentAttributes){
      attribute.staves ??= 1;
    }

    int divisions = gc.currentAttributes[0].divisions!;

    // first system start point
    Offset topLeft = const Offset(50,100);
    SystemLayout system = SystemLayout(topX: topLeft.dx, topY: topLeft.dy,maxWidth: maxWidth,partsNumber: score.parts.length, divisions: divisions);
    bool isFirst = true;
    
    // Title & composer

    TextObject title = TextObject(text: score.title,
                         textStyle: const TextStyle(fontSize: 30, color: Colors.black),
                          x: maxWidth/2, y: 30);

    TextObject composer = TextObject(text: score.composer,
     textStyle: const TextStyle(fontSize: 30, color: Colors.black),
      x: maxWidth/8*7, y: 70);

    drawables.add(title);
    drawables.add(composer);

    // Generate systems
    int i = 0;
    while (i < score.parts.first.measures.length){
      minWidth = 0;

      // Current measures in all parts
      List<Measure> currentMeasures = [];
      for (int j = 0; j < score.parts.length; j++){
        currentMeasures.add(score.parts[j].measures[i]);
      }

      // Update attributes if the measure have it
      if (currentMeasures.first.attributes != null){
        for (int j = 0; j < score.parts.length; j++){
          gc.currentAttributes[j] = gc.currentAttributes[j].update(currentMeasures[j].attributes!);
        }
      }

      minWidth = system.calcMinWidth(measureList:currentMeasures, isFirst:isFirst);
      
      // Add measures to system
      if (system.minWidth + minWidth <= gc.systemWidth){
        system.addMeasure(measureList: currentMeasures);
        isFirst = false;
      } else { // close system and create new
        system.finish();
        systems.add(system);

        isFirst = true;
        topLeft += Offset(0, systems.last.height + gc.mc.systemSpace);
        system = SystemLayout(topX: topLeft.dx, topY: topLeft.dy, maxWidth: maxWidth,partsNumber: score.parts.length, divisions: divisions);
        i--;
      }
      
      i++;
    }


    // Add last system
    system.finish();
    systems.add(system);

    for(int i = 0; i < systems.length; i++){

      List<Drawable> systemDrawable = [];

      // Different color for different system and parts
      for(int j = 0; j < systems[i].parts.length; j++){
        List<Drawable> partDrawable = [];
        Color? partColor;
        if(colorPart){
         partColor = HSLColor.fromAHSL(1.0, ((i * 137 - 90) + j * 30) % 360, 0.78, 0.62).toColor();
        }

        partDrawable.addAll(systems[i].parts[j].getDrawables());
        for(Drawable i in partDrawable){
          if(i.runtimeType == LineObject){
            i as LineObject;
            i.color = partColor ?? i.color;
          }
        }
        systemDrawable.addAll(partDrawable);
      }

      drawables.addAll(systemDrawable);

    }
    
    return ScoreObject(drawables: drawables);

  }

}

abstract class MusicLayout{
  /// Top x coordinate of the layout
  double? topX;
  /// Top y coordinate of the layout
  double? topY;
  /// Width of the layout
  double width;
  /// Height of the layout
  double height;
  /// Minmum possible width of the layout
  double minWidth;

  MusicLayout({this.topX, this.topY, this.width = 0, this.height = 0, this.minWidth = 0});

  SystemContext get sc;

  /// Calculate the minimum width of the layout
  double calcMinWidth({List<Measure>? measureList, Measure? measure, bool isFirst = false, int partNumber = 0});

  /// Add measure data to the layout
  void addMeasure({List<Measure>? measureList, Measure? measure}){}

  /// Finish the layout
  void finish();

  /// Set the starting position of the layout
  void setCoordinates();

  /// Get all of the drawables from the layout
  List<Drawable> getDrawables();
} 