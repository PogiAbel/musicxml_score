import 'package:flutter/material.dart';

import '../dom/measure.dart';

/// Class for holding the music context informations ie. staff space, system space, size etc.
class MusicContext {
  /// Spatium(Spatia)/sp/staff space/space/stave space - most important distance in music notation
  double sp = 10;
  /// Distances between the staffs, from top to bottom
  double staffSpace = 20;
  /// Distance between systems
  double systemSpace = 100;
  /// Distance between parts
  double partSpace = 40;
  /// Default stretch factor
  double stretch = 1.2;
  /// Default size of the text font
  double textFontSize = 40;
  /// Default staff line size
  double staffLineWidth = 1;
  /// Default light barline size
  double barlineLightWidth = 1.5;
  /// Default heavy barline size
  double barlineHeavyWidth = 3.5;
  /// Ledger line width
  double ledgerLineWidth = 1.8;
  /// Stem width
  double stemWidth = 1.2;

  MusicContext();

}

/// Singletion class for holding
/// the current attributes and music context
class GlobalContext{
  MusicContext mc;
  List<Attributes> currentAttributes;
  double systemWidth;
  late TextStyle glyphStyle;
  late TextStyle textStyle;

  static GlobalContext? _instance;

  factory GlobalContext(){
    _instance ??= GlobalContext._();
    return _instance!;
  }

  double get staveDistance => mc.sp;

  GlobalContext._()
  : mc = MusicContext(),
    currentAttributes = [Attributes()],
    systemWidth = 300 
    {
      mc.textFontSize = 2*mc.sp;
      glyphStyle = TextStyle(
        fontSize: mc.sp * 4,
        fontFamily: 'Bravura',
        color: Colors.black,
        height: 1
      );
      textStyle = TextStyle(
        fontSize: mc.textFontSize,
        color: Colors.black,
        height: 1
      );
    }

  TextStyle glyphStyleWithColor(Color color){
    return TextStyle(
      fontSize: mc.sp * 4,
        fontFamily: 'Bravura',
        color: color,
        height: 1
    );
  }
}