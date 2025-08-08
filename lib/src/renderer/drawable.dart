import 'package:flutter/material.dart';

import '../generated/glyph_bboxes.dart';
import '../generated/glyph_definitions.dart';

/// The different types of [Drawable] objects (this project supports)
enum DrawableType{
  /// Musical glyph from SMuFL
  glyph,
  /// Line
  line,
  /// Dot
  dot,
  /// Normal text
  text
}

/// A bounding box
/// 
/// x,y is the top left corner of the box
class BBox{
  double x;
  double y;
  double width;
  double height;

  BBox({required this.x, required this.y, required this.width, required this.height});

  @override
  String toString() {
    return "{BBox: x: $x, y: $y, width: $width, height: $height}";
  }

  void draw(Canvas canvas){
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
  }

  /// Check collision between two [BBox], margin shrinks the bbox
  bool collidesWith(BBox other, {double margin = 0}) {
    double cX = x + margin;
    double cY = y + margin;
    double cW = width - margin * 2;
    double cH = height - margin * 2;

    double oX = other.x + margin;
    double oY = other.y + margin;
    double oW = other.width - margin * 2;
    double oH = other.height - margin * 2;

    return (cX < oX + oW &&
            cX + cW > oX &&
            cY < oY + oH &&
            cY + cH > oY);
  }
}

/// Interface for objects that can be drawn
abstract interface class Drawable{
  double _x;
  double _y;
  Offset offset;
  DrawableType type;
  late BBox bbox;

  Drawable({required this.type, required double x, required double y, this.offset = const Offset(0,0)}): _x = x, _y = y;


  @override
  String toString() {
    return "{Drawable: type: $type, x: $x, y: $y, offset: $offset}";
  }

  double get x => _x;

  set x(double x) {
    _x = x;
    bbox.x = x;
  }

  double get y => _y;

  set y(double y) {
    _y = y;
    bbox.y = y;
  }

  /// Bounding box rigthest x coordinate
  double get right => bbox.x + bbox.width;

  /// Bounding box bottom y coordinate
  double get bottom => bbox.y + bbox.height;

  /// Bounding box top y coordinate
  double get top => bbox.y;

  /// Bounding box leftest x coordinate
  double get left => bbox.x;

  void draw(Canvas canvas);

  void drawBbox(Canvas canvas, {List<DrawableType> exclude = const []}){
    if(exclude.contains(type)){
      return;
    }
    bbox.draw(canvas);
  }

  Drawable copy();

}

/// A drawable object for musical glyphs
/// 
/// x,y is the left-middle point of the glyph
class GlyphObject extends Drawable{
  final Glyph glyph;
  TextStyle textStyle;
  late String glyphString;
  late GlyphBBox gbbox;

  GlyphObject({required this.glyph,required this.textStyle, required super.x, required super.y, super.type = DrawableType.glyph}){
    glyphString = glyphFontcodeMap[glyph]!;
    gbbox = (glyphBboxes[glyph]! * (textStyle.fontSize!/4));
    bbox = BBox(x: x, y: y + gbbox.northEast.dy, width: gbbox.southWest.dx.abs() + gbbox.northEast.dx, height: gbbox.southWest.dy + gbbox.northEast.dy.abs());
  }

  @override
  void draw(Canvas canvas) {
    TextPainter textPainter = TextPainter(
      text:TextSpan(
          text: glyphString,
          style: textStyle,
        ),
      textDirection: TextDirection.ltr,
      
    );
    textPainter.layout();

    // Get the top left corner for the textPainter
    double baselineOffset = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    Offset drawPosition = Offset(x, y - baselineOffset);

    textPainter.paint(canvas, drawPosition);
  }

  @override
  Drawable copy() => GlyphObject(glyph: glyph, textStyle: textStyle, x: x, y: y);
  
  @override
  set x(double x) {
    _x = x;
    bbox.x = x;
  }
  
  @override
  set y(double y) {
    _y = y;
    bbox.y = y + gbbox.northEast.dy;
  }

}

/// A drawable object for lines
/// 
/// x,y is the top or left (middle?) point of the line
class LineObject extends Drawable{
  double length;
  final double thickness;
  final bool horizontal;
  final Offset endOffset;
  Color color;

  LineObject({required this.length, required this.thickness, required this.horizontal, required super.x, required super.y, super.type = DrawableType.line, this.color = Colors.black, this.endOffset = const Offset(0,0)}){
    double topX = horizontal ? x : x - thickness/2;
    double topY = horizontal ? y - thickness/2 + endOffset.dy: y;
    bbox = BBox(x: topX, y: topY, width: horizontal ? length : thickness, height: horizontal ? thickness + endOffset.dy : length);
    
  }

  @override
  void draw(Canvas canvas) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness;

    if(horizontal){
      canvas.drawLine(Offset(x, y), Offset(x + length, y) + endOffset, paint);
    }else{
      canvas.drawLine(Offset(x, y), Offset(x, y + length) + endOffset, paint);
    }
  }

  @override
  Drawable copy() => LineObject(length: length, thickness: thickness, horizontal: horizontal, x: x, y: y, endOffset: endOffset);

  @override
  set x(double x) {
    _x = x;
    bbox.x = horizontal ? x : x - thickness/2;
  }
  
  @override
  set y(double y) {
    _y = y;
    bbox.y = horizontal ? y - thickness/2 : y;
  }

}

/// A drawable object for dots
/// 
/// x,y is the middle point of the circle
class DotObject extends Drawable{
  final double radius;
  Color color;

  DotObject({required this.radius, required super.x, required super.y, super.type = DrawableType.dot, this.color = Colors.black}){
    bbox = BBox(x: x - radius, y: y - radius, width: radius*2, height: radius*2);
  }

  @override
  void draw(Canvas canvas) {
    Paint paint = Paint()
      ..color = color;

    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  Drawable copy() => DotObject(radius: radius, x: x, y: y);

  @override
  set x(double value) {
    _x = value;
    bbox.x = value - radius;
  }

  @override
  set y(double value) {
    _y = value;
    bbox.y = value - radius;
  }
}

/// A drawable object for text
/// 
/// x,y is the center/middle point of the text
class TextObject extends Drawable{
  final String text;
  TextStyle textStyle;
  late TextPainter textPainter; 

  TextObject({required this.text, required this.textStyle, required super.x, required super.y, super.type = DrawableType.text}){
    textPainter = TextPainter(
      text:TextSpan(
          text: text,
          style: textStyle,
        ),
      textDirection: TextDirection.ltr,
      
    );
    textPainter.layout();

    // Get the top left corner for the textPainter
    double baselineOffset = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);

    bbox = BBox(x: x - (textPainter.width/2), y: y - baselineOffset, width: textPainter.width, height: textPainter.height);
  }

  @override
  set x(double x){
    _x = x;
    bbox.x = x - x - (textPainter.width/2);
  }

  @override
  set y(double y){
    double baselineOffset = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    _y = y;
    bbox.y = y - baselineOffset;
  }

  @override
  void draw(Canvas canvas) {
    TextPainter textPainter = TextPainter(
      text:TextSpan(
          text: text,
          style: textStyle,
        ),
      textDirection: TextDirection.ltr,
      
    );
    textPainter.layout();

    // Get the top left corner for the textPainter
    double baselineOffset = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    double textWidth = textPainter.width;
    Offset drawPosition = Offset(x - (textWidth/2), y - baselineOffset); // x,y is the center of the text, but the drawposition is the top left corner of the text

    textPainter.paint(canvas, drawPosition);
  }
  
  @override
  Drawable copy() => TextObject(text: text, textStyle: textStyle, x: x, y: y);
}

extension DeepCopy on List<Drawable> {
  List<Drawable> deepCopy(){
    return map((e) => e.copy()).toList();
  }
}