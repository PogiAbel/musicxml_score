import '../extension/list_extension.dart';
import '../dom/measure.dart';
import '../renderer/drawable.dart';

import 'part_layout.dart';
import 'system_layout.dart';
import 'layout.dart';
import 'music_context.dart';
import 'staff_layout.dart';

/// The [MeasureLayout] class manages the staffs in it.
class MeasureLayout extends MusicLayout{
  /// Global context
  GlobalContext gc = GlobalContext();
  /// [Measure] containing the data 
  final Measure measureData;
  /// Staffs in the measure
  List<StaffLayout> staffs = [];
  /// number of the [PartLayout] it is in
  int partNumber;
  /// Is it a first measure in the system
  bool isFirst = false;
  /// Reference to the parent [PartLayout]
  PartLayout partLayout;
  /// Measure's end barline type
  Barline endBarline = Barline(type: "light", location: "left");
  /// Measure's start barline type
  Barline? startBarline;


  MeasureLayout({required this.partLayout,required this.measureData, required this.partNumber}){
    for (var i = 0; i < gc.currentAttributes[partNumber].staves!; i++){
      staffs.add(StaffLayout(measureLayout: this,measureData: measureData,staffNumber: i + 1));
    }
  }

  double get movableStart => staffs.reduce((v,e) => v.movableStart > e.movableStart ? v : e).movableStart;

  set movableStart(double value){
    for(var s in staffs){
      s.movableStart = value;
    }
  }

  @override
  SystemContext get sc => partLayout.sc;

  double get localHeight => (staffs.last.topY! + staffs.last.highestY + staffs.last.localHeight) - (staffs.first.topY! + staffs.first.highestY);

  /// Lowest Y point of the measure in global space
  double get lowestY {
    return staffs.last.lowestY + staffs.last.topY!;
  }

  @override
  double calcMinWidth({List<Measure>? measureList, Measure? measure, bool isFirst = false, int partNumber = 0}){
    double minWidth = 0;
    for (var staff in staffs){
      double currentWidth = staff.calcMinWidth(measure: measureData, partNumber: partNumber, isFirst: isFirst);
      minWidth = minWidth > currentWidth ? minWidth : currentWidth;
    }
    return minWidth;
  }

  @override
  void finish(){
    for(var staff in staffs){
      staff.finish();
    }

    width = staffs.fold(0.0, (v,e) => v > e.width ? v : e.width);
    height = staffs.fold(0.0, (v,e) => v + e.height) + (staffs.length-1) * gc.mc.staffSpace;
  }

  @override
  void setCoordinates(){

    for (int i = 0; i<staffs.length; i++){
      double staffHeights = staffs.take(i).fold(0.0, (v,e) =>v+e.height);

      staffs[i].topX = topX;
      staffs[i].topY = topY! + staffHeights + (i * gc.mc.staffSpace);
      
      staffs[i].setCoordinates();
    }
  }

  @override
  List<Drawable> getDrawables(){
    List<Drawable> drawables = [];
    for (int i = 0; i < staffs.length; i++){
      drawables.addAll(staffs[i].getDrawables());
    }

    // Bounding box for the measure
    // DotObject bbox = DotObject(radius: 0, x: topX!, y: topY!);
    // bbox.bbox = BBox(x: topX!, y: topY!, width: width, height: height);
    // // double top = staffs.first.highestY + topY!;
    // // bbox.bbox = BBox(x: topX!, y: top, width: width, height: localHeight);

    // drawables.add(bbox);

    return drawables;
  }

  /// Stretch the measure to fit the given width
  void stretch(double finalWidth){
    for(var staff in staffs){
      staff.stretch(finalWidth);
    }
    width = finalWidth;
  }

  double stretchWeight(){
    double min = 0;
    for(var staff in staffs){
      double staffWeight = staff.stretchWeigth();
      min = staffWeight > min ? staffWeight : min;
    }

    return min;
  }

  void matchMids(List<double> midPoints){
    for (int i = 0; i<staffs.length; i++){
      staffs[i].matchMiddle(midPoints[i]);
    }
  }

  void correctHeight(){
    for (int i = 0; i<staffs.length; i++){
      double staffHeights = partLayout.staffHeights.take(i).fold(0.0, (v,e) =>v+e);

      staffs[i].topX = topX;
      staffs[i].topY = topY! + staffHeights + (i * gc.mc.staffSpace);
      staffs[i].height = partLayout.staffHeights[i];
    }

    height = partLayout.staffHeights.sum + (staffs.length-1) * gc.mc.staffSpace;
  }

  bool collisionCheck(List<Drawable> items, double margin) {
    // Sort by left edge (x-coordinate)
    items.sort((a, b) => a.bbox.x.compareTo(b.bbox.x));

    List<Drawable> activeList = [];

    // Sweep and check collisions
    for (int i = 0; i < items.length; i++) {
      Drawable current = items[i];

      // Remove non-overlapping items from active list (with margin)
      activeList.removeWhere((d) => d.bbox.x + d.bbox.width + margin < current.bbox.x);

      // Check collision within the active list
      for (var other in activeList) {
        if (current.bbox.collidesWith(other.bbox, margin: margin)) {
          return true; // Found a collision, return immediately
        }
      }

      // Add current item to active list
      activeList.add(current);
    }

    return false; // No collisions found
  }

}