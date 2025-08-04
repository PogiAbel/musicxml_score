import 'package:test/test.dart';

void main() {
  group('Note position from middle',(){
    double staffSpace = 10;
    double middle = -2 * staffSpace; // -20

    test('Note on bottom line',() {
      double y = -40;
      double offset = (middle - y) / staffSpace;
      expect(offset, 2);
    });
    test('Note on top line', (){
      double y = 0;
      double offset = (middle - y) / staffSpace;
      expect(offset, -2);
    });
  });

}