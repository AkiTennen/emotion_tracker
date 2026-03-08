import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class BodyMapScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Color emotionColor;
  final bool readOnly;
  final BodyType? overrideBodyType;

  const BodyMapScreen({
    super.key,
    this.initialData,
    required this.emotionColor,
    this.readOnly = false,
    this.overrideBodyType,
  });

  @override
  State<BodyMapScreen> createState() => _BodyMapScreenState();
}

class _BodyMapScreenState extends State<BodyMapScreen> {
  late List<List<Offset>> _frontPaths;
  late List<List<Offset>> _backPaths;
  late BodyType _bodyType;

  @override
  void initState() {
    super.initState();
    _bodyType = widget.overrideBodyType ?? SettingsService.getBodyType();
    _loadInitialData();
  }

  void _loadInitialData() {
    _frontPaths = [];
    _backPaths = [];

    if (widget.initialData != null) {
      final front = widget.initialData!['frontPaths'] as List?;
      final back = widget.initialData!['backPaths'] as List?;

      if (front != null) {
        for (var path in front) {
          _frontPaths.add((path as List).map((p) => Offset(p[0] as double, p[1] as double)).toList());
        }
      }
      if (back != null) {
        for (var path in back) {
          _backPaths.add((path as List).map((p) => Offset(p[0] as double, p[1] as double)).toList());
        }
      }
    }
  }

  Map<String, dynamic> _saveData() {
    return {
      'version': 1,
      'bodyType': _bodyType.name,
      'frontPaths': _frontPaths.map((path) => path.map((p) => [p.dx, p.dy]).toList()).toList(),
      'backPaths': _backPaths.map((path) => path.map((p) => [p.dx, p.dy]).toList()).toList(),
    };
  }

  void _clear() {
    setState(() {
      _frontPaths.clear();
      _backPaths.clear();
    });
  }

  void _undo() {
    setState(() {
      if (_backPaths.isNotEmpty) {
        _backPaths.removeLast();
      } else if (_frontPaths.isNotEmpty) {
        _frontPaths.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? 'View Body Map' : 'Body Map'),
        actions: widget.readOnly 
          ? null 
          : [
              IconButton(onPressed: _undo, icon: const Icon(Icons.undo)),
              IconButton(onPressed: _clear, icon: const Icon(Icons.delete_outline)),
              IconButton(
                onPressed: () => Navigator.pop(context, _saveData()),
                icon: const Icon(Icons.check),
              ),
            ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isPortrait = height > width;

          return InteractiveViewer(
            maxScale: 5.0,
            child: GestureDetector(
              onPanStart: widget.readOnly ? null : (details) {
                final localPos = details.localPosition;
                setState(() {
                  if (isPortrait) {
                    // Vertical split (Top/Bottom)
                    final midY = height / 2;
                    if (localPos.dy < midY) {
                      _frontPaths.add([Offset(localPos.dx / width, localPos.dy / midY)]);
                    } else {
                      _backPaths.add([Offset(localPos.dx / width, (localPos.dy - midY) / midY)]);
                    }
                  } else {
                    // Horizontal split (Left/Right)
                    final midX = width / 2;
                    if (localPos.dx < midX) {
                      _frontPaths.add([Offset(localPos.dx / midX, localPos.dy / height)]);
                    } else {
                      _backPaths.add([Offset((localPos.dx - midX) / midX, localPos.dy / height)]);
                    }
                  }
                });
              },
              onPanUpdate: widget.readOnly ? null : (details) {
                final localPos = details.localPosition;
                setState(() {
                  if (isPortrait) {
                    final midY = height / 2;
                    if (localPos.dy < midY) {
                      _frontPaths.last.add(Offset(localPos.dx / width, localPos.dy / midY));
                    } else {
                      _backPaths.last.add(Offset(localPos.dx / width, (localPos.dy - midY) / midY));
                    }
                  } else {
                    final midX = width / 2;
                    if (localPos.dx < midX) {
                      _frontPaths.last.add(Offset(localPos.dx / midX, localPos.dy / height));
                    } else {
                      _backPaths.last.add(Offset((localPos.dx - midX) / midX, localPos.dy / height));
                    }
                  }
                });
              },
              child: Stack(
                children: [
                  // Silhouettes
                  Flex(
                    direction: isPortrait ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(child: _buildPlaceholderBox('FRONT')),
                      Expanded(child: _buildPlaceholderBox('BACK')),
                    ],
                  ),
                  // Drawing Overlay
                  CustomPaint(
                    size: Size(width, height),
                    painter: BodyMapPainter(
                      frontPaths: _frontPaths,
                      backPaths: _backPaths,
                      color: widget.emotionColor,
                      isPortrait: isPortrait,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderBox(String label) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Text(
          '$label\n(${_bodyType.name.toUpperCase()})',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class BodyMapPainter extends CustomPainter {
  final List<List<Offset>> frontPaths;
  final List<List<Offset>> backPaths;
  final Color color;
  final bool isPortrait;

  BodyMapPainter({
    required this.frontPaths,
    required this.backPaths,
    required this.color,
    required this.isPortrait,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    // Draw Front Paths
    for (var path in frontPaths) {
      if (path.isEmpty) continue;
      final screenPath = Path();
      if (isPortrait) {
        final midY = height / 2;
        screenPath.moveTo(path[0].dx * width, path[0].dy * midY);
        for (var i = 1; i < path.length; i++) {
          screenPath.lineTo(path[i].dx * width, path[i].dy * midY);
        }
      } else {
        final midX = width / 2;
        screenPath.moveTo(path[0].dx * midX, path[0].dy * height);
        for (var i = 1; i < path.length; i++) {
          screenPath.lineTo(path[i].dx * midX, path[i].dy * height);
        }
      }
      canvas.drawPath(screenPath, paint);
    }

    // Draw Back Paths
    for (var path in backPaths) {
      if (path.isEmpty) continue;
      final screenPath = Path();
      if (isPortrait) {
        final midY = height / 2;
        screenPath.moveTo(path[0].dx * width, (path[0].dy * midY) + midY);
        for (var i = 1; i < path.length; i++) {
          screenPath.lineTo(path[i].dx * width, (path[i].dy * midY) + midY);
        }
      } else {
        final midX = width / 2;
        screenPath.moveTo((path[0].dx * midX) + midX, path[0].dy * height);
        for (var i = 1; i < path.length; i++) {
          screenPath.lineTo((path[i].dx * midX) + midX, path[i].dy * height);
        }
      }
      canvas.drawPath(screenPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) => true;
}
