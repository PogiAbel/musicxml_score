import '../extension/list_extension.dart';
import '../dom/measure.dart';
import '../renderer/drawable.dart';

import 'layout.dart';
import 'music_context.dart';
import 'part_layout.dart';

class SystemLayout extends MusicLayout{
  GlobalContext gc = GlobalContext();
  late SystemContext systemContext;
  late List<PartLayout> parts;
  List<List<Measure>> systemMeasureList = [];

  SystemLayout({required super.topX, required super.topY,required int divisions,required double maxWidth, int partsNumber = 1}){

  systemContext = SystemContext(divisions: divisions, maxWidth: maxWidth);
  parts = List.generate(partsNumber, (index) => PartLayout(partNumber: index, systemLayout: this));

  }

  @override
  SystemContext get sc => systemContext;

  @override
  double get height => parts.fold(0.0, (v, e) => v + e.height) + (parts.length-1) * gc.mc.partSpace;


  @override
  /// Calculate the minimum width of the new measure in the system
  double calcMinWidth({List<Measure>? measureList, Measure? measure, bool isFirst = false, int partNumber = 0, int shortest = 100}){
    int newShortestNote = measureList!.reduce((v, e) => v.shortestNote < e.shortestNote ? v : e).shortestNote;

    if(newShortestNote < sc.shortestNote){
      sc.shortestNote = newShortestNote;
      recalculate();
    }

    double minWidth = 0;
    for (int j = 0; j < parts.length; j++){
      double currentWidth = parts[j].calcMinWidth(measure:measureList[j], isFirst: isFirst, shortest: sc.shortestNote);
      minWidth = minWidth > currentWidth ? minWidth : currentWidth;
    }
    return minWidth;
  }
 
  @override
  /// Add all part's measure to the current system
  void addMeasure({List<Measure>? measureList, Measure? measure}){
    systemMeasureList.add(measureList!);

    for (var i = 0; i < parts.length; i++){
      parts[i].addMeasure(measure: measureList[i]);
    }
    double mWidth = calcMinWidth(measureList: measureList, isFirst: parts.first.measureLayouts.length == 1 ? true : false);
    minWidth += mWidth;

    sc.minMeasureWidths.add(mWidth);
    sc.movableStarts.add(0);
  }

  @override
  /// Closes the system, calculate all of the drawables and system sizes
  void finish(){
    double space = sc.maxWidth - minWidth;
    List<double> spaceWeights = getStretchWeights();


    double allWeigth = spaceWeights.sum;
    List<double> spaces = spaceWeights.map((e){
      return e * space / allWeigth;
    }).toList();

    sc.measureSpaces = spaces;

    // distribute remaining space based on spaceWeigth and finish parts
    for (var part in parts){
      part.finish();
    }
    
    for (var part in parts){
      part.setMovableStart();
    }

    setCoordinates();
    
  }

  @override
  void setCoordinates(){
    for (int i = 0; i<parts.length; i++){
      double partHeights = parts.take(i).fold(0.0, (v,e) => v+ e.height);
      parts[i].topX = topX!;
      parts[i].topY = topY! + partHeights + (i * gc.mc.partSpace );

      parts[i].setCoordinates();
    }
  }

  List<double> getStretchWeights(){
    List<double> min = parts.first.stretchWeight();

    for (int i = 1; i<parts.length; i++){
      List<double> currentWeights = parts[i].stretchWeight();
      min = List.generate(min.length, (i) => min[i] > currentWeights[i] ? min[i] : currentWeights[i]);
    }

    return min;
  }

  @override
  List<Drawable> getDrawables(){
    List<Drawable> drawables = [];
    for (var part in parts){
      drawables.addAll(part.getDrawables());
    }
    return drawables;
  }

  /// If found a shorter note, recalculate minWidth of the measures in the system
  void recalculate(){
    minWidth = 0;
    sc.minMeasureWidths = [];
    for(int i = 0; i< systemMeasureList.length; i++){
      double mWidth = calcMinWidth(measureList:systemMeasureList[i], isFirst: i == 0 ? true : false);
      minWidth += mWidth;
      sc.minMeasureWidths.add(mWidth);
    }
  }
}

class SystemContext{
  /// Global score division
  int divisions;
  /// Shortest note duration in the system
  int shortestNote;
  /// The calculated measure widths in the system
  List<double>? measureSpaces;
  /// Minimum width of the measures in the system
  List<double> minMeasureWidths = [];
  /// The movableStart for each measure in the system
  List<double> movableStarts = [];
  /// The maximum allowed width for the system
  double maxWidth;

  SystemContext({required this.divisions, this.shortestNote = 100, this.measureSpaces,required this.maxWidth});
}