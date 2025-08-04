import '../renderer/drawable.dart';
import '../dom/measure.dart';

import 'layout.dart';
import 'staff_layout.dart';
import 'system_layout.dart';
import 'music_context.dart';
import 'measure_layout.dart';

class PartLayout extends MusicLayout{
  /// Global context
  GlobalContext gc = GlobalContext();
  /// Index of the part, starts from 0
  int partNumber;
  /// List of [MeasureLayout]s in the part
  List<MeasureLayout> measureLayouts;
  /// Reference to parent [SystemLayout]
  SystemLayout systemLayout;
  /// List that will contain the staffs maximum height
  List<double> staffHeights;

  PartLayout({ required this.systemLayout,required this.partNumber,List<MeasureLayout>? measureLayout,List<double>? staffDistances})
  : measureLayouts = measureLayout ?? List.empty(growable: true),
    staffHeights = staffDistances ?? List.empty(growable: true);

  @override
  SystemContext get sc => systemLayout.sc;

  double get localHeight => measureLayouts.reduce((v,e) => v.lowestY > e.lowestY ? v:e).lowestY - topY!;

  @override
  double calcMinWidth({List<Measure>? measureList, Measure? measure, bool isFirst = false, int partNumber = 0, int shortest = 0}){
    MeasureLayout m = MeasureLayout(partLayout: this, measureData: measure!, partNumber: partNumber);
    return m.calcMinWidth(isFirst:isFirst);
  }

  @override
  void addMeasure({List<Measure>? measureList, Measure? measure}){
    measureLayouts.add(MeasureLayout(partLayout: this, measureData: measure!, partNumber: partNumber));
    double testMinWidth = measureLayouts.last.calcMinWidth();
    minWidth += testMinWidth;
  }

  @override
  /// Finish the measures to fit width
  void finish(){
    measureLayouts.first.isFirst = true;

    // Finish measures and stretch them
    for(int i=0; i<measureLayouts.length; i++){
      measureLayouts[i].finish();
      measureLayouts[i].stretch(sc.minMeasureWidths[i] + sc.measureSpaces![i]);
    }
    
    // Get movable starts for later
    for (int i = 0; i < measureLayouts.length; i++) {
      if(measureLayouts[i].movableStart > sc.movableStarts[i]){
        sc.movableStarts[i] = measureLayouts[i].movableStart;
      }
    }

    width = measureLayouts.fold(0.0, (v,e) => v+e.width);

  }

  @override
  void setCoordinates(){
    double localWidth = 0;
    
    // Set coordinates
    for (var measure in measureLayouts){
      measure.topX = topX! + localWidth;
      measure.topY = topY;

      measure.setCoordinates();

      localWidth += measure.width;
    }

    // Match middle points to the lowest
    List<double> staffMids = [];
    for(int i = 0; i < gc.currentAttributes[partNumber].staves!; i++){
      double lowest = measureLayouts.reduce((v,e) =>  v.staffs[i].middleY > e.staffs[i].middleY ? v : e).staffs[i].middleY;
      staffMids.add(lowest);
    }

    for(var m in measureLayouts){
      m.matchMids(staffMids);
    }

    // Get correct global staff height
    staffHeights = [];
    for(int i = 0; i < gc.currentAttributes[partNumber].staves!; i++){
      double lowest = measureLayouts.reduce((v,e) => v.staffs[i].lowestY > e.staffs[i].lowestY ? v : e).staffs[i].lowestY;
      double highest = measureLayouts.reduce((v,e) => v.staffs[i].highestY < e.staffs[i].highestY ? v : e).staffs[i].highestY;
      staffHeights.add(lowest - highest);
    }
    
    for(var m in measureLayouts){
      m.correctHeight();
    }

    height = measureLayouts.first.height;

  }

  
  List<double> stretchWeight(){
    List<double> min = [];

    for(var measure in measureLayouts){
      min.add(measure.stretchWeight());
    }

    return min;
  }

  @override
  List<Drawable> getDrawables(){
    List<Drawable> drawables = [];
    List<Drawable> staffLines = [];


    for (var measure in measureLayouts){
      drawables.addAll(measure.getDrawables());
    }

    // Draw staff lines for every staff
    double length = drawables.fold(0.0, (v,e) => v > e.right ? v : e.right);
    for(int i =0; i<measureLayouts.first.staffs.length;i++){
      StaffLayout staff = measureLayouts.first.staffs[i];
      double lx = topX!;
      double ly = staff.topY! + staff.middleY - 2 *gc.staveDistance;

      for (int j = 0; j<5; j++){
        LineObject line = LineObject(x: lx, y: ly + j*gc.staveDistance, length: length - topX!, thickness: gc.mc.staffLineWidth, horizontal: true);
        staffLines.add(line);
      }
    }

    drawables.insertAll(0, staffLines);


    // Bounding box for the part
    DotObject bbox = DotObject(radius: 0, x: topX!, y: topY!);
    bbox.bbox = BBox(x: topX!, y: topY!, width: width, height: height);

    drawables.add(bbox);

    return drawables;
  }

  void setMovableStart(){
    for(int i = 0; i<measureLayouts.length; i++){
      measureLayouts[i].movableStart = sc.movableStarts[i];
    }
  }
}