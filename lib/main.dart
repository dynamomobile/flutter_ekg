import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EKG',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EKGScreen(),
    );
  }
}

class EKGScreen extends StatefulWidget {
  @override
  _EKGScreenState createState() => _EKGScreenState();
}

class _EKGScreenState extends State<EKGScreen> with TickerProviderStateMixin {
  final ekgPainter = EKGPainter();

  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: Duration(milliseconds: 1200), vsync: this);
    _animation = Tween<double>(begin: 1, end: 0).animate(_animationController);
    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
      future: _loadImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          ekgPainter.image = snapshot.data;
        }
        return AnimatedBuilder(
          animation: _animation,
          child: _canvas(),
          builder: (context, child) {
            ekgPainter._offset = _animation.value;
            return _canvas();
          },
        );
      },
    ));
  }

  Future<ui.Image> _loadImage() async {
    final ByteData data = await rootBundle.load('assets/dot.png');
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Widget _canvas() {
    return LayoutBuilder(
      builder: (context, size) {
        return Container(
          color: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                CustomPaint(
                  painter: ekgPainter,
                  size: Size.square(size.maxWidth),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EKGPainter extends CustomPainter {
  ui.Image image;

  double _offset = 1.0;
  var _ekgMap = <Offset>[];

  void _populateEkgMap() {
    int k = 0;

    _ekgMap.clear();

    final shift = (45 - _offset * 45) / 180;

    while (k < 10) {
      _ekgMap.add(Offset(k / 180 - shift, 0.0));
      k++;
    }

    while (k < 15) {
      _ekgMap.add(Offset(k / 180 - shift, sin(1.0 * pi * (k - 10) / (5)) / 5));
      k++;
    }

    while (k < 17) {
      _ekgMap.add(Offset(k / 180 - shift, 0.0));
      k++;
    }

    while (k < 21) {
      _ekgMap
          .add(Offset(k / 180 - shift, -sin(1.0 * pi * (k - 17) / (4)) / 10.0));
      k++;
    }

    while (k < 26) {
      _ekgMap.add(Offset(k / 180 - shift, sin(1.0 * pi * (k - 21) / (5))));
      k++;
    }

    while (k < 31) {
      _ekgMap
          .add(Offset(k / 180 - shift, -sin(1.0 * pi * (k - 26) / (5)) / 2.0));
      k++;
    }

    while (k < 35) {
      _ekgMap.add(Offset(k / 180 - shift, 0.0));
      k++;
    }

    while (k < 46) {
      _ekgMap
          .add(Offset(k / 180 - shift, sin(1.0 * pi * (k - 35) / (11)) / 8.0));
      k++;
    }

    while (k < 180 - _offset * 45) {
      _ekgMap.add(Offset(k / 180 - shift, _ekgMap[k % 45].dy));
      k++;
    }

    _ekgMap.removeRange(0, 45 - (_offset * 45).floor());

    _ekgMap = _ekgMap
        .map((offset) => Offset(offset.dx, 0.5 - offset.dy / 3))
        .toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    _populateEkgMap();

    canvas.transform(Matrix4.identity().scaled(size.width).storage);

    var path = Path();
    path.addPolygon(_ekgMap, false);

    paint.color = Colors.green;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3 / size.width;
    paint.strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    canvas.transform(Matrix4.identity().scaled(1 / size.width).storage);

    if (image != null) {
      paint.color = Colors.white;
      final imageOffset =
          _ekgMap.last * size.width - Offset(image.width / 2, image.height / 2);
      paint.colorFilter = ColorFilter.matrix([
        // 4x5 matrix
        0.2, 0.0, 0.0, 0.0,
        0.0, 0.6, 0.0, 0.0,
        0.0, 0.0, 0.3, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
      ]);
      canvas.drawImage(image, imageOffset, paint);
      paint.strokeWidth = 10;
      paint.strokeCap = StrokeCap.round;
      canvas.drawPoints(
          ui.PointMode.points, [_ekgMap.last * size.width], paint);
    }

    _drawGrid(canvas, paint, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  void _drawGrid(Canvas canvas, Paint paint, Size size) {
    paint.color = Colors.white38;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.strokeJoin = StrokeJoin.bevel;
    for (double xy = 0; xy < 1; xy += 0.05) {
      canvas.drawLine(Offset(xy * size.width, 0),
          Offset(xy * size.width, size.height), paint);
      canvas.drawLine(Offset(0, xy * size.width),
          Offset(size.width, xy * size.height), paint);
    }
  }
}
