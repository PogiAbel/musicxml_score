import 'dart:math';
import 'package:flutter/material.dart';
import 'package:music_notes/music_notes.dart' as mn;

import '../extension/string_extension.dart';
import '../extension/list_extension.dart';
import '../generated/glyph_anchors.dart';
import '../generated/glyph_definitions.dart';
import '../renderer/drawable.dart';
import '../dom/note.dart';
import '../dom/measure.dart';

import 'measure_layout.dart';
import 'layout.dart';
import 'music_context.dart';
import 'system_layout.dart';

class StaffLayout extends MusicLayout{
  /// Global context and informations
  GlobalContext gc = GlobalContext();
  /// Staff number starts from 1
  int staffNumber;
  /// The movable items in the measure ie. notes, rests
  List<Anchor> movable;
  /// The fixed items in the measure ie. time signature, key signature, clef
  List<Anchor> fixed;
  /// The text items in the measure ie. lyrics, dynamics
  List<Drawable> text;
  /// Other items in the measure ie. slurs, ties, barlines
  List<Drawable> other;
  /// The [MeasureItem]s with their drawables
  Map<String, dynamic> items;
  /// The middle Y of the staff (the middle line)
  double middleY = 0;
  /// Reference to the parent [MeasureLayout]
  MeasureLayout measureLayout;
  /// The start position of the movable items
  double movableStart = 0;
  /// Stretch weigth for the note horizontal space calculation
  double stertchFactor = 1;
  /// The [Measure] data
  Measure measureData;
  /// Fixed width between static items
  late double fixedWidth;

  StaffLayout({required this.measureLayout,required this.measureData,this.staffNumber = 1, List<Anchor>? movable, List<Anchor>? fixed, List<Drawable>? text, List<Drawable>? other}) 
      : movable = movable ?? List.empty(growable: true),
        fixed = fixed ?? List.empty(growable: true),
        text = text ?? List.empty(growable: true),
        other = other ?? List.empty(growable: true),
        items = {}
        {
          // Deep copy the measure
          measureData = Measure.from(measureData);
          filterMeasure();

          height = 4*gc.staveDistance;
          fixedWidth = gc.staveDistance;
          middleY = gc.staveDistance*2;
        }

  @override
  SystemContext get sc => measureLayout.sc;

  Attributes get staffAttributes => measureData.attributes != null ? gc.currentAttributes[measureLayout.partNumber].update(measureData.attributes!) : gc.currentAttributes[measureLayout.partNumber];

  mn.Pitch get middlePitch{
    Clef clef = staffAttributes.clefs![staffNumber-1];
    return mn.Pitch.parse(clef.noteName);
  }

  double get localHeight => lowestY - highestY;

  /// Get the top y point in the staff in staff space, in canvas coordinates its the lowest value
  double get highestY {
    List<Drawable> allDrawable = getLocalDrawables();
    return allDrawable.reduce((v,e) => v.top < e.top ? v : e).top;
  }

  /// Get the bottom y point in the staff in staff space, in canvas coordinates its the highest y value
  double get lowestY {
    List<Drawable> allDrawable = getLocalDrawables();
    return allDrawable.reduce((v,e) => v.bottom > e.bottom ? v : e).bottom;
  }

  /// Get the bottom y point in the staff in global space, in canvas coordinates its the highest y value
  double? get globalLowestY => topY != null ? topY!+lowestY : null;

  /// Get the top y point in the staff in global space, in canvas coordinates its the lowest y value
  double? get globalhighestY => topY != null ? topY!+highestY : null;


  /// Filter the measure to only include the items in the staff
  void filterMeasure(){
    bool inStaff = true;
    measureData.items = measureData.items.where((item) {
      if (item is Note){
        if(item.staff == staffNumber){
          inStaff = true;
          return true; // Note is in staff
        } else{
          inStaff = false; // Note not in staff
        }
      }
      return inStaff; // Everything else
    }).toList();
  }

  /// Calculate the minimum width of the staff
  @override
  double calcMinWidth({List<Measure>? measureList, Measure? measure, bool isFirst = false, int partNumber = 0}){
    double currentX = 0;
    
    // If the measure has attributes, calculate the width of the attributes
    // They are the fixed items in the measure
    if(measure!.attributes != null){
      if(measure.attributes!.clefs != null){
        Clef clef = measure.attributes!.clefs![0];
        Drawable clefGlyph = GlyphObject(glyph: clef.glyph, textStyle: gc.glyphStyle, x: currentX, y: 10);

        Anchor a = Anchor(x: currentX, duration: 0, other: [clefGlyph], voice: 1);
        fixed.add(a);

        currentX += clefGlyph.bbox.width + fixedWidth;
      }

      if (measure.attributes!.key != null){
        // If the measure has a key, calculate the width of the key
        Glyph type = measure.attributes!.key!.fifths > 0 ? Glyph.accidentalSharp : Glyph.accidentalFlat;
        Drawable key ;
        Anchor a = Anchor(x: currentX, duration: 0, voice: 1);

        for (int j = 0; j<measure.attributes!.key!.fifths.abs(); j++){
          key = GlyphObject(glyph: type, textStyle: gc.glyphStyle, x: currentX, y: measure.attributes!.key!.accidentalList(type, gc.currentAttributes[partNumber].clefs![staffNumber-1].glyph)[j]*gc.staveDistance);
          currentX += key.bbox.width;
          a.other.add(key);
        }

        fixed.add(a);

        currentX += fixedWidth;
      }

      if (measure.attributes!.time != null){
        // If the measure has a time signature, calculate the width of the time signature
        // TODO: implement beat too if neceseary in later
        Time time = measure.attributes!.time!;
        Drawable beatGlyph = GlyphObject(glyph: time.beatGlyph, textStyle: gc.glyphStyle, x: currentX, y: 0);

        Anchor a = Anchor(x: currentX, duration: 0, other: [beatGlyph], voice: 1);
        fixed.add(a);

        currentX += beatGlyph.bbox.width + fixedWidth;
      }
    } else if (isFirst){
      // If the measure has no attributes and is the first measure, calculate the width of the default attributes
      Anchor a;
      Glyph clefType = gc.currentAttributes[partNumber].clefs![staffNumber-1].glyph;
      Drawable clef = GlyphObject(glyph: clefType, textStyle: gc.glyphStyle, x: currentX, y: 0);
      a = Anchor(x: currentX, duration: 0, other: [clef], voice: 1);
      fixed.add(a);
      currentX += clef.bbox.width + fixedWidth;

      Glyph keyType = gc.currentAttributes[partNumber].key!.fifths > 0 ? Glyph.accidentalSharp : Glyph.accidentalFlat;
      Drawable? key;
      a = Anchor(x: currentX, duration: 0, voice: 1);
      for (int j = 0; j<gc.currentAttributes[partNumber].key!.fifths.abs(); j++){

        key = GlyphObject(glyph: keyType, textStyle: gc.glyphStyle, x: currentX, y: gc.currentAttributes[partNumber].key!.accidentalList(keyType, gc.currentAttributes[partNumber].clefs![staffNumber-1].glyph)[j]*gc.staveDistance);

        currentX += key.bbox.width;
        a.other.add(key);
      }
      fixed.add(a);
      currentX += (key == null ? fixedWidth : fixedWidth + key.bbox.width);
      
      Glyph timeType = gc.currentAttributes[partNumber].time!.beatGlyph;
      Drawable time = GlyphObject(glyph: timeType, textStyle: gc.glyphStyle, x: currentX, y: 0);
      a = Anchor(x: currentX, duration: 0, other: [time], voice: 1);
      fixed.add(a);
      currentX += time.bbox.width + fixedWidth;
    }

    // Calculate the width of the notes
    movableStart = currentX;
    currentX = 0;
    double t = 2; // strecth weigth
    Anchor currentAnchor = Anchor(x: currentX, duration: 0, voice: 1);

    // Measure movable items
    for (var item in measureData.items){
      switch (item){
      case final Note item:
        Drawable noteGlyph = GlyphObject(glyph: Glyph.noteheadBlack, textStyle: gc.glyphStyle, x: currentX, y: 0);
        if (item.isChord){
          currentAnchor.add(item, [noteGlyph]);
          break;
        }
        currentAnchor = Anchor(x: currentX, duration: item.duration, voice: item.voice);
        currentAnchor.add(item, [noteGlyph]);
        movable.add(currentAnchor);

        currentX += getNoteSpace(t, item.duration, sc.shortestNote) * 2 * gc.staveDistance;
        break;
      case final Barline item:
        // Drawable barlineGlyph = LineObject(length: 4*gc.staveDistance, thickness: gc.mc.barlineLightWidth, horizontal: false, x: currentX, y: 0);
        // currentAnchor = Anchor(x: currentX, duration: 0,voice: 1, other: [barlineGlyph]);
        // movable.add(currentAnchor);

        // currentX += gc.staveDistance;
        if(item.repeatType != null && item != measureData.items.last){
          currentX += gc.staveDistance*1.5;
        }
        break;
      case final Backup item:
        // Backup backup = item;
        // int duration = backup.duration;
        // int j = movable.length - 1;
        // while (duration > 0){
        //   currentX = movable[j].x;
        //   duration -= movable[j].duration;
        // }
        break;
      case _ :
        break;
      }
    }
    // double lastSpace = getNoteSpace(t, movable.last.duration, sc.shortestNote) * 2 * gc.staveDistance;
    minWidth = currentX + movableStart;
    minWidth += minWidth > movable.last.right + fixedWidth ? 0 : fixedWidth ;
    return minWidth;
  }

  /// Calculates the measure's stretch weigth
  double stretchWeigth(){
    double weight = 1;

    for (var item in measureData.items){
      double itemWeight = 0;

     if (item.runtimeType == Note){
      item as Note;
        if(!item.isChord){
          itemWeight += 1;
          if(item.accidental != null){
            itemWeight += 0.5;
          }
        }
        weight += itemWeight;
     }
     if(item.runtimeType == Backup){
        return weight;
      }
    }

    return weight;
  }

  /// Stretch the mesure to the given width
  void stretch(double finalWidth){

    double ratio = (finalWidth - movableStart) / (width - movableStart);
    for (int i = 1; i<movable.length; i++) {
      double diff = (movable[i].x * ratio) - movable[i].x;
      movable[i].moveX(diff);
    }
    if(movable[0].x != 0){
      double newX = finalWidth/2 - movable[0].width/2 - movableStart;
      movable[0].newX(newX);
    }

    generateStem();

    width = finalWidth;
  }

  /// Finish the measure minimum vertical placement 
  /// 
  /// Calculate the vertical positions of the notes
  /// and their attributes: accidental, dots
  @override
  void finish(){
    fixed = [];
    movable = [];
    other = [];
    double currentX = gc.staveDistance;
    Anchor currentAnchor = Anchor(x: 0, duration: 0, voice: 1);

    DotObject createNoteDot({required Anchor currentAnchor, required Drawable note}){
      DotObject dot = DotObject(radius: gc.staveDistance/6, x: note.right + gc.staveDistance/2, y: note.y.roundUpTo(gc.staveDistance)-gc.staveDistance/2);

      // if(currentAnchor.collidesWithGlyph(dot)){
      //   dot.y += gc.staveDistance;
      //   if(currentAnchor.collidesWithGlyph(dot)){
      //     dot.y -= 2*gc.staveDistance;
      //   }
      // }

      return dot;
    }

    GlyphObject createAccidental({required Anchor currentAnchor,required Note note, required double y}){
      Glyph accidentalGlyph;
      GlyphObject accidental;

      accidentalGlyph = Glyph.values.firstWhere((e) => e.name.contains("accidental${note.accidental!.capitalize()}"));

      accidental = GlyphObject(glyph: accidentalGlyph, textStyle: gc.glyphStyle, x: currentAnchor.x - gc.staveDistance, y: y);

      while(currentAnchor.collidesWithGlyph(accidental)){
        accidental.x -= gc.staveDistance/2;
      }
      try{
        Anchor previsious = movable.elementAt(movable.length-2);
        double diff = accidental.x - (previsious.x + previsious.width);
        if(diff < 0){
          diff = diff.abs();
          currentAnchor.moveX(diff);
          currentX += diff;
          accidental.x += diff;
        }
      } catch (e){}

      return accidental;
    }

    void generateNote({required Note item}){
      double posY;
      Glyph noteGlyph = Glyph.noteheadBlack;
      Drawable noteObject;
      GlyphObject? accidental;
      double notePosition = currentX;

      // Note head glyph
      if(item.pitch != null){
        mn.Pitch notePitch = mn.Pitch.parse("${item.pitch!.step}${item.pitch!.octave}");
        posY = noteDistance(notePitch) + middleY;
        noteGlyph = getNoteHead(item.type);
      } else {
        posY = item.type != "" ? middleY : middleY - gc.staveDistance;
        noteGlyph = getRestGlyph(item.type != "" ? item.type : "whole");
      }

      noteObject = GlyphObject(glyph: noteGlyph, textStyle: gc.glyphStyle, x: notePosition, y: posY);


      // Ledger lines for notes outside the staff
      List<LineObject> ledgerLines = [];
      // Above
      if(posY <= (middleY - 3*gc.staveDistance)){
        double start = middleY - 3*gc.staveDistance;
        for(start; start >= posY; start -= gc.staveDistance){
          LineObject ledger = LineObject(length: noteObject.bbox.width + 0.8*gc.staveDistance, thickness: gc.mc.ledgerLineWidth, horizontal: true, x: notePosition-0.4*gc.staveDistance, y: start);

          ledgerLines.add(ledger);
        }
      }
      // Under
      if(posY >= (middleY + 3*gc.staveDistance)){
        double start = middleY + 3*gc.staveDistance;
        for(start; start <= posY; start += gc.staveDistance){
          LineObject ledger = LineObject(length: noteObject.bbox.width + 0.8*gc.staveDistance, thickness: gc.mc.ledgerLineWidth, horizontal: true, x: notePosition-0.4*gc.staveDistance, y: start);

          ledgerLines.add(ledger);
        }
      }

      // Chord note management
      if (item.isChord){
        noteObject.x = currentAnchor.x;

        // Shift notehead if it collides with other
        if(noteObject.bbox.collidesWith(currentAnchor.itemMap.values.last.first.bbox, margin: 1)){

          double shift = noteObject.bbox.width - 1;
          Drawable lastNoteHead = currentAnchor.itemMap.values.last.first;
          Drawable? secondLast;

          if(item.stemDirection == "up" || item.stemDirection == ""){
            noteObject.x += shift;
          } else {

            try {
              secondLast = currentAnchor.itemMap.values.elementAt(currentAnchor.itemMap.values.length-2).first;
            } catch(e){}

            lastNoteHead.x -= shift;

            if(secondLast != null && lastNoteHead.bbox.collidesWith(secondLast.bbox)){
              lastNoteHead.x += shift;
              noteObject.x -= shift;
            }
          }

          for (LineObject line in ledgerLines) {
            line.length = 2 * noteObject.bbox.width + 0.8*gc.staveDistance;
            line.x = currentAnchor.itemMap.values.reduce((v,e) => v.first.x < e.first.x ? v : e).first.x - 0.4*gc.staveDistance;
          }
        }


        currentAnchor.add(item, [noteObject, ...ledgerLines]);

        // Accidental
        if(item.accidental != null){
          accidental = createAccidental(currentAnchor: currentAnchor, note: item, y: noteObject.y);
          currentAnchor.itemMap[item]!.add(accidental);
        }

        // Dot
        if(item.dots > 0){
          currentAnchor.itemMap[item]!.add(createNoteDot(currentAnchor: currentAnchor, note: noteObject));
        }

        return;
      }

      // Not a chord item: rest or single note
      currentAnchor = Anchor(x: currentX, duration: item.duration, voice: item.voice);
      currentAnchor.add(item, [noteObject, ...ledgerLines]);

      if(item.accidental != null){
          accidental = createAccidental(currentAnchor: currentAnchor, note: item, y: noteObject.y);
          currentAnchor.itemMap[item]!.add(accidental);
      }

      if(item.dots > 0){
          currentAnchor.itemMap[item]!.add(createNoteDot(currentAnchor: currentAnchor, note: noteObject));
        }

      movable.add(currentAnchor);

      currentX += getNoteSpace(stertchFactor, item.duration, sc.shortestNote) * 2 * gc.staveDistance;
      return;
    }

    if(measureLayout.isFirst){
      layoutAttributes(all: true);
    } else if(measureData.attributes != null ){
      layoutAttributes();
    }

    // Add fixed offset
    currentX += fixed.isNotEmpty ? fixed.first.other.last.right : 0;

    movableStart = currentX;
    currentX = 0;

    // Measure movable items
    for (var item in measureData.items){
      switch (item){
      case final Note item:
        generateNote(item: item);
        break;

      case final Barline item:
        if(item.repeatType != null && item != measureData.items.last){
          double start = fixed.isEmpty ? 0 : movableStart;
          LineObject light = LineObject(length: 4*gc.staveDistance, thickness: gc.mc.barlineLightWidth, horizontal: false, x: start, y: middleY-2*gc.staveDistance);
          LineObject heavy = LineObject(length: 4*gc.staveDistance, thickness: gc.mc.barlineHeavyWidth, horizontal: false, x: start - gc.staveDistance/2, y: middleY-2*gc.staveDistance);
          DotObject dot1 = DotObject(radius: gc.staveDistance/6, x: start+gc.staveDistance*0.75, y: middleY+gc.staveDistance/2);
          DotObject dot2 = dot1.copy() as DotObject;
          dot2.y -= gc.staveDistance;

          movableStart += gc.staveDistance;
          other.addAll([light,heavy,dot1,dot2]);

          // Currently support for repeats need more work for in measure barlines
          measureLayout.startBarline = item;
        } else{
          measureLayout.endBarline = item;
        }
        break;
      case final Backup item:
      if(item == measureData.items.last){break;}
        // int duration = item.duration;
        // int j = movable.length - 1;
        // while (duration > 0){
        //   currentX = movable[j].x;
        //   duration -= movable[j].duration;
        // }
        currentX = 0;
        break;
      case _ :
        break;
      }
    }
    width = movable.reduce((v,e) => v.right > e.right ? v : e).x + getNoteSpace(stertchFactor, movable.last.duration, sc.shortestNote)* 2 * gc.staveDistance + movableStart;
    // width += width > movable.last.right + fixedWidth ? 0 : fixedWidth ;

    Note rest = measureData.items.firstWhere((e) => e is Note) as Note;

    if(rest.isRestMeasure){
      Anchor restAnchor = movable.firstWhere((e) => e.itemMap.containsKey(rest));
      double newX = width/2 - restAnchor.width/2;
      restAnchor.newX(newX);
    }

    if(movable.first.left+movableStart < movableStart){
      movableStart += movable.first.left.abs();
    }

    double tHeight = lowestY - highestY;
    height = tHeight > height ? tHeight : height;
  }

  /// Generate all of the stems and beams for the notes
  void generateStem(){
    List<Anchor> beamList = [];

    for(var anchor in movable.where((e) => e.itemMap.isNotEmpty)){
      MeasureItem first = anchor.itemMap.keys.first;

      if(first is Note && first.type != "whole"){
        if(!first.isRest){
          if(first.beam != null){
            if(first.beam!.first.type != BeamType.end){
              beamList.add(anchor);
            } else {
              generateBeam([...beamList, anchor]);
              beamList = [];
            }
            continue;
          }

          switch(first.stemDirection){
            case "up":
              generateSingleAnchorStem(anchor, isUp: true);
              break;
            case "down":
              generateSingleAnchorStem(anchor, isUp: false);
              break;
            default:
            debugPrint("Stem direction error");
          }
          
        }
      }
    }
  }

  /// Given an [Anchor] calculates the normal stem's length
  double calculateAnchorStemLength({required Anchor anchor,required  bool isUp}){
    GlyphObject bottom = anchor.bottomItem.$2;
    GlyphObject top =  anchor.topItem.$2;

    double base;
    double length;

    base = calculateBase(note: bottom, isUp: isUp);
    length = base * gc.staveDistance + (bottom.y - top.y);

    return length;
  }

  /// For a single [Anchor] generates its stem and flag if needed
  void generateSingleAnchorStem(Anchor anchor, {required bool isUp}){
    GlyphObject bottom = anchor.bottomItem.$2;
    GlyphObject top =  anchor.topItem.$2;
    Note first = anchor.itemMap.keys.first as Note;

    double base;
    double length;
    LineObject stem;

    base = calculateBase(note: bottom, isUp: isUp);
    length = calculateAnchorStemLength(anchor: anchor, isUp: isUp);

    stem = generateStemLine(length: length, pos: isUp ? bottom : top, isUp: isUp);



    if(first.type.contains("th")){
      GlyphObject tail;

      if(base < 3.5){
        length = 3.5 * gc.staveDistance + (bottom.y - top.y);
        stem = generateStemLine(length: length, pos: top, isUp: isUp);
      }

      if (isUp){
        Glyph glyphType = Glyph.values.firstWhere((e) => e.name.contains("flag${first.type}Up"));
        tail = GlyphObject(glyph: glyphType, textStyle: gc.glyphStyle, x: stem.x - gc.mc.staffLineWidth/2, y: stem.y);
      } else {
        Glyph glyphType = Glyph.values.firstWhere((e) => e.name.contains("flag${first.type}Down"));
        tail = GlyphObject(glyph: glyphType, textStyle: gc.glyphStyle, x: stem.x - gc.mc.staffLineWidth/2, y: stem.y + stem.length);
      }

      anchor.itemMap.values.first.add(tail);
    }
    anchor.itemMap.values.first.add(stem);
  }

  /// From the noteheads position calculates the stem's base length in stave spaces 
  double calculateBase({required GlyphObject note,required bool isUp}){
    double base = 3.5;

    if(isUp){
      base = switch((middleY - note.y)/gc.staveDistance){
          >= 1.5 => 2.5,
          >= 0 => 3,
          < -3 => (note.y - middleY )/gc.staveDistance,
          _ => 3.5
         };
    } else {
      base = switch((note.y - middleY)/gc.staveDistance){
          >= 1.5 => 2.5,
          >= 0 => 3,
          < -3 => (middleY - note.y)/gc.staveDistance,
          _ => 3.5
         };
    }

    return base;
  }

  /// Generate a stem [LineObject] for the [pos] glyph width given [length] and [isUp] direction
  LineObject generateStemLine({required double length, required  GlyphObject pos,required  bool isUp}){
    double startX;
    double startY;
    GlyphAnchor gAnchor = glyphAnchors[pos.glyph]!;
    Offset glyphOffset;

    if(isUp){
      glyphOffset = gAnchor.stemUpSE * (gc.staveDistance);
      length += glyphOffset.dy;
      startY = pos.y + glyphOffset.dy - length;
      startX = pos.x + glyphOffset.dx - gc.mc.stemWidth/2;
    } else {
      glyphOffset = gAnchor.stemDownNW * (gc.staveDistance);
      length -= glyphOffset.dy;
      startY = pos.y + glyphOffset.dy;
      startX = pos.x + glyphOffset.dx + gc.mc.stemWidth/2;
    }

    return LineObject(length: length, thickness: gc.mc.stemWidth, horizontal: false, x: startX, y: startY);
  }

  /// Given a list of [Anchor]s generates the stem lines and beam [LineObject]s for them
  void generateBeam(List<Anchor> items) {
    double startX;
    double endX;
    double startY = 0;
    double beamSlope = 0;

    bool isUp = (items.first.itemMap.keys.first as Note).stemDirection == "up";

    if(isUp){
      startX = items.first.x + glyphAnchors[Glyph.noteheadBlack]!.stemUpSE.dx * (gc.staveDistance) - gc.mc.stemWidth;
      endX = items.last.x + glyphAnchors[Glyph.noteheadBlack]!.stemUpSE.dx * gc.glyphStyle.fontSize!/4;
    } else {
      startX = items.first.x + glyphAnchors[Glyph.noteheadBlack]!.stemDownNW.dx * gc.glyphStyle.fontSize!/4;
      endX = items.last.x + glyphAnchors[Glyph.noteheadBlack]!.stemDownNW.dx * gc.glyphStyle.fontSize!/4 + gc.mc.stemWidth;
    }

    List<GlyphObject> borders = isUp
        ? items.map((e) => e.topItem.$2).toList()
        : items.map((e) => e.bottomItem.$2).toList();

    List<double> normalStemLengths =
        items.map((e) => calculateAnchorStemLength(anchor: e, isUp: isUp)).toList();

    GlyphObject border = borders.reduce((v, e) =>
        isUp ? (v.y > e.y ? e : v) : (v.y > e.y ? v : e));
    int index = borders.indexOf(border);

    startY = (isUp ? items[index].bottomItem.$2.y :
                     items[index].topItem.$2.y)
              + normalStemLengths[index] * (isUp ? -1 : 1);

    for(int i = 0;i< items.length; i++){
      if(isUp){
        GlyphObject bottom = items[i].bottomItem.$2;
        items[i].itemMap.values.last.add(generateStemLine(length: bottom.y-startY, pos: bottom, isUp: isUp));
      } else{
        GlyphObject top = items[i].topItem.$2;
        items[i].itemMap.values.last.add(generateStemLine(length: startY - top.y, pos: top, isUp: isUp));
      }
    }

    // Logic to determine beam start and end position

    // Create the Beam Object
    LineObject beam = LineObject(
        length: endX - startX,
        thickness: gc.staveDistance / 2,
        horizontal: true,
        x: startX,
        y: startY,
        endOffset: Offset(0,beamSlope * gc.staveDistance)
    );

    // Apply the beam to the first anchor
    items.first.itemMap.values.first.add(beam);
}
  
  /// From the note type get the note head glyph
  Glyph getNoteHead(String type){
    switch(type){
      case "whole":
      return Glyph.noteheadWhole;
      case "half":
      return Glyph.noteheadHalf;
      default:
      return Glyph.noteheadBlack;
    }
  }
  
  /// From the note type get the rest glyph
  Glyph getRestGlyph(String type){
    return Glyph.values.firstWhere((e) => e.name.contains("rest${type.capitalize()}"));
  }

  @override
  void setCoordinates(){
    if(highestY+topY! < topY!){
      double diff = topY! - (highestY + topY!);
      shiftY(diff);
    }

    if(movable.last.right + fixedWidth/2 + movableStart >= width){
      movable.last.moveX((width) - (movable.last.right + fixedWidth/2 + movableStart));
    }
  }

  /// Shift all items in the Y axis, so the middle point matches with [point]
  void matchMiddle(double point){
    double diff = point - middleY;
    shiftY(diff);
  }

  /// Shift all items in the Y axis by [value]
  void shiftY(double value){
    var drawables = getLocalDrawables();

      for(var item in drawables){
        item.y += value;
      }

      middleY += value;
  }

  /// Generates the attributes in the staff
  /// 
  /// If [all] is true, then its a first measure and generates all of the attributes
  /// 
  /// If [all] is false, only generate the ones that are in the [Measure] data
  void layoutAttributes({bool all = false}){
    double currentX = gc.staveDistance/2;
    int partNumber = measureLayout.partNumber;
    Anchor fixedAnchors = Anchor(x: currentX, duration: 0, voice: 1);

    // Clef
    Clef? c;
    if(measureData.attributes?.clefs != null){
        c = gc.currentAttributes[partNumber].clefs![staffNumber-1];
    } else if(all){
      c = gc.currentAttributes[partNumber].clefs![staffNumber-1];
    }
    if(c != null){
      GlyphObject cObject = GlyphObject(glyph: c.glyph, textStyle: gc.glyphStyle, x: currentX, y: (5-c.line) * gc.staveDistance);
      fixedAnchors.other.add(cObject);

      currentX += cObject.bbox.width + fixedWidth;
    }

    // Accidentals
    MusicKey? key;
    if(measureData.attributes?.key != null){
      key = measureData.attributes!.key!;
    } else if(all){
      key = gc.currentAttributes[partNumber].key!;
    }

    if(key!=null){
      Glyph keyType = key.fifths > 0 ? Glyph.accidentalSharp : Glyph.accidentalFlat;

      for (int j = 0; j<gc.currentAttributes[partNumber].key!.fifths.abs(); j++){
        double linePos = getStaffLineDistance(key.accidentalList(keyType, gc.currentAttributes[partNumber].clefs![staffNumber-1].glyph)[j]);
        linePos = linePos - 2 * gc.staveDistance; // correction to be the distance from the middle point

        Drawable keyObject = GlyphObject(glyph: keyType, textStyle: gc.glyphStyle, x: currentX, y:linePos + middleY);

        fixedAnchors.other.add(keyObject);

        currentX += keyObject.bbox.width + gc.staveDistance/4;
      }
      currentX += (- gc.staveDistance/4) + fixedWidth;
    }

    // Time signature
    Time? time;
    if(measureData.attributes?.time != null){
      time = measureData.attributes!.time!;
    }

    if(time != null){
      Drawable beat = GlyphObject(glyph: time.beatGlyph, textStyle: gc.glyphStyle, x: currentX, y: middleY - gc.staveDistance);

      Drawable beatType = GlyphObject(glyph: time.timeGlyph, textStyle: gc.glyphStyle, x: currentX, y: middleY + gc.staveDistance);

      fixedAnchors.other.addAll([beat,beatType]);

    }

    fixed.add(fixedAnchors);
  }

  /// Return note space using the musescore formula
  double getNoteSpace(double t,int duration, int shortest){
    return 1 - 0.647 * t + t * 0.647 * sqrt(duration / shortest);
  }

  /// The distance from the middle note
  double noteDistance(mn.Pitch pitch){
    int diff = middlePitch.note.baseNote.ordinal - pitch.note.baseNote.ordinal;
    int octave = middlePitch.octave - pitch.octave;

    double a = ((octave * 7) + diff) * (gc.staveDistance/2);
    return a;    
  }

  /// Returns the distance from lines
  /// 
  /// example: (staveDistance = 10)
  /// 1 line = 10
  /// 1.5 line = 15
  /// -2 line = -20
  double getStaffLineDistance(double line){
    return line * gc.staveDistance;
  }

  /// Get drawables in global coordinates;
  @override
  List<Drawable> getDrawables(){
    List<Drawable> drawables = List.empty(growable: true);
    List<Drawable> moved = List.from(movable.expand((element) => element.getAllDrawables()));
    moved = moved.deepCopy();

    for(var item in moved){
      item.x += movableStart;
    }

    drawables.addAll(fixed.expand((element) => element.getAllDrawables()));
    drawables.addAll(moved);
    drawables.addAll(text);
    drawables.addAll(other);


    List<Drawable> copy = drawables.deepCopy();
    double top = middleY - 2*gc.staveDistance;
    LineObject barline;
    switch(measureLayout.endBarline.type){
      case "light-heavy":
      barline= LineObject(x: width - gc.staveDistance/2, y: middleY - 2*gc.staveDistance, length: 4*gc.staveDistance, thickness: 1.3, horizontal: false);
      copy.add(LineObject(length:  4*gc.staveDistance, thickness: gc.mc.barlineHeavyWidth, horizontal: false, x: width, y: top));
      case _:
      barline= LineObject(x: width, y: top, length: 4*gc.staveDistance, thickness: gc.mc.barlineLightWidth, horizontal: false);
    }

    if(measureLayout.endBarline.repeatType != null){
      DotObject dot1 = DotObject(radius: gc.staveDistance/6, x: width-gc.staveDistance*1.25, y: middleY+gc.staveDistance/2);
      DotObject dot2 = dot1.copy() as DotObject;
      dot2.y -= gc.staveDistance;
      copy.addAll([dot1,dot2]);
    }

    copy.add(barline);

    for (var drawable in copy){
      drawable.x += topX!;
      drawable.y += topY!;
    }

    // Staff bounding box
    // Drawable bbox = DotObject(radius: 0, x: topX!, y: topY!);
    // bbox.bbox = BBox(x: topX!, y: topY!, width: width, height: height);
    // // bbox.bbox = BBox(x: topX!, y: topY! + highestY, width: width, height: localHeight);

    // copy.add(bbox);

    return copy;
  }

  /// Get drawables in local coordinates
  List<Drawable> getLocalDrawables(){
    List<Drawable> drawables = List.empty(growable: true);
    drawables.addAll(fixed.expand((element) => element.getAllDrawables()));
    drawables.addAll(movable.expand((element) => element.getAllDrawables()));
    drawables.addAll(text);
    drawables.addAll(other);

    return drawables;
  }
}

/// Anchor items in one place
class Anchor{
  /// Start x of the anchor
  double x;
  /// Duration of the anchor
  int duration;
  /// Voice the anchor is in, starts at 1
  int voice;
  /// Other non conventional drawables
  List<Drawable> other;
  /// [MeasureItem]s in the anchor and they drawables
  Map<MeasureItem, List<Drawable>> itemMap;

  Anchor({required this.x, required this.duration,required this.voice, List<Drawable>? other,Map<MeasureItem, List<Drawable>>? itemMap})
  : other = other ?? List.empty(growable: true),
    itemMap = itemMap ?? {};

  double get width => right - left;

  double get right => getAllDrawables().reduce((v,e) => v.right > e.right ? v : e).right;

  double get left => getAllDrawables().reduce((v,e) => v.left < e.left ? v : e).left;
  

  /// Returns the top/highest note in the anchor in a map: {[MeasureItem]:[GlyphObject]} with the top note and its glyph head
  (MeasureItem, GlyphObject) get topItem {
    MeasureItem top = itemMap.keys.whereType<Note>().reduce((v,e) {
       return (itemMap[v]!.first.y < itemMap[e]!.first.y) ? v : e;
    });
    return (top, itemMap[top]!.first as GlyphObject);
  }

  /// Returns the bottom/lowest note in the anchor in a map: {[MeasureItem]:[GlyphObject]} with the top note and its glyph head
  (MeasureItem, GlyphObject) get bottomItem {
  MeasureItem bottom = itemMap.keys.whereType<Note>().reduce((v,e) {
       return (itemMap[v]!.first.y < itemMap[e]!.first.y) ? e : v;
    });
    return (bottom, itemMap[bottom]!.first as GlyphObject);
  }

  void add(MeasureItem item, List<Drawable>? drawables){
    itemMap[item] = drawables ?? List.empty(growable: true);
  }

  void moveX(double amount){
    x += amount;
    for(var d in getAllDrawables()){
      d.x += amount;
    }
  }

  void newX(double newX){    
    x = newX;
    for(var d in getAllDrawables()){
      d.x = newX;
    }
  }

  bool collidesWithGlyph(Drawable glyph){
    for(var g in getAllDrawables()){
      if(g is GlyphObject && g.bbox.collidesWith(glyph.bbox)){
        return true;
      }
    }

    return false;
  }

  List<Drawable> getDrawables(MeasureItem item){
    return itemMap[item] ?? List.empty(growable: true);
  }

  List<Drawable> getAllDrawables(){
    List<Drawable> drawables = List.empty(growable: true);

    drawables.addAll(other);

    for (var element in itemMap.values) {
      drawables.addAll(element);
    }
    return drawables;
  }
}