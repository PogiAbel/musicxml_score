import 'package:flutter/material.dart';

import 'score_object.dart';

/// Custom Canvas for rendering the [ScoreObject]
class ScoreCanvas extends StatefulWidget {
  const ScoreCanvas({super.key,required this.size, required this.scoreObject});
  final ScoreObject scoreObject;
  final Size size;

  @override
  State<ScoreCanvas> createState() => _ScoreCanvasState();

}

class _ScoreCanvasState extends State<ScoreCanvas> {
  final TransformationController _transformationController = TransformationController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 5),
      ),
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.1, // Minimum zoom out.
        maxScale: 40.0, // Maximum zoom in.
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        child: CustomPaint(
            painter: ScorePainter(widget.scoreObject, _transformationController),
            size: widget.size,
          ),
      ),
    );
  }
}


class ScorePainter extends CustomPainter {
  final ScoreObject score;
  final TransformationController _transformationController;

  ScorePainter(this.score, this._transformationController);

  @override
  void paint(Canvas canvas, Size size) {
    // Clip overdraws
    // final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // canvas.clipRect(rect);
    
    // Canvas default border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);

    /// ---------------------------------------------------------  SCALE ---------------------------------------------------------
    canvas.scale(1);
    // _drawGrid(canvas, size);

    score.draw(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  void _drawGrid(Canvas canvas, Size size){
      // draw a grid
    Color gridColor = const Color.fromARGB(20, 158, 158, 158);
    for (int i = 0; i < size.height/10; i++) {
      canvas.drawLine(
        Offset(0, i * 10.0),
        Offset(size.width, i * 10.0),
        Paint()..color = gridColor,
      );
    }
        for (int i = 0; i < size.width/10; i++) {
      canvas.drawLine(
        Offset(i * 10.0, 0),
        Offset(i * 10.0, size.height),
        Paint()..color = gridColor,
      );
    }
  }
}