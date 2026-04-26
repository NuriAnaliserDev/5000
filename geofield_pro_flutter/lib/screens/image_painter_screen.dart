import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_localizations.dart';

class ImagePainterScreen extends StatefulWidget {
  final String imagePath;
  const ImagePainterScreen({super.key, required this.imagePath});

  @override
  State<ImagePainterScreen> createState() => _ImagePainterScreenState();
}

class _ImagePainterScreenState extends State<ImagePainterScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<DrawnLine> _lines = [];
  Color _selectedColor = Colors.red;
  final double _strokeWidth = 3.0;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _lines.add(DrawnLine([details.localPosition], _selectedColor, _strokeWidth));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _lines.last.path.add(details.localPosition);
    });
  }

  void _clear() {
    setState(() => _lines.clear());
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() => _lines.removeLast());
    }
  }

  Future<void> _saveImage() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${dir.path}/annotated_$timestamp.png';
      
      final file = File(newPath);
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      Navigator.of(context).pop(); // pop loading
      Navigator.of(context).pop(newPath); // return new path
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // pop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.locRead('save_first_hint'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.loc('draw_on_photo'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clear),
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF1976D2)),
            onPressed: _saveImage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              panEnabled: false,
              scaleEnabled: false, // disable scale for easy drawing
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.file(File(widget.imagePath), fit: BoxFit.contain),
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          child: CustomPaint(
                            painter: PhotoPainter(_lines),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _colorButton(Colors.red),
                  _colorButton(Colors.blue),
                  _colorButton(Colors.green),
                  _colorButton(Colors.orange),
                  _colorButton(Colors.white),
                  _colorButton(Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorButton(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
          boxShadow: [
            if (isSelected) BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)
          ],
        ),
      ),
    );
  }
}

class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double strokeWidth;
  DrawnLine(this.path, this.color, this.strokeWidth);
}

class PhotoPainter extends CustomPainter {
  final List<DrawnLine> lines;
  PhotoPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      final path = Path();
      if (line.path.isNotEmpty) {
        path.moveTo(line.path.first.dx, line.path.first.dy);
        for (int i = 1; i < line.path.length; i++) {
          path.lineTo(line.path[i].dx, line.path[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(PhotoPainter oldDelegate) => oldDelegate.lines.length != lines.length || oldDelegate.lines != lines;
}
