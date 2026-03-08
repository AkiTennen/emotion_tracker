import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final TransformationController _transformationController = TransformationController();
  
  bool _isDrawing = false;
  bool _hadMultiplePointers = false;

  @override
  void initState() {
    super.initState();
    _bodyType = widget.overrideBodyType ?? SettingsService.getBodyType();
    _loadInitialData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
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
            transformationController: _transformationController,
            maxScale: 5.0,
            minScale: 1.0,
            panEnabled: true,
            scaleEnabled: true,
            onInteractionStart: (details) {
              if (widget.readOnly) return;
              
              if (details.pointerCount == 1) {
                _isDrawing = true;
                _hadMultiplePointers = false;
                _handleInteraction(details.localFocalPoint, true, isPortrait, width, height);
              } else {
                _isDrawing = false;
                _hadMultiplePointers = true;
              }
            },
            onInteractionUpdate: (details) {
              if (widget.readOnly) return;

              if (details.pointerCount > 1) {
                _hadMultiplePointers = true;
                if (_isDrawing) {
                  setState(() {
                    _isDrawing = false;
                    // Remove accidental path created when first finger landed
                    if (_frontPaths.isNotEmpty && _frontPaths.last.length < 5) _frontPaths.removeLast();
                    if (_backPaths.isNotEmpty && _backPaths.last.length < 5) _backPaths.removeLast();
                  });
                }
                return;
              }

              // Only continue drawing if we ONLY had one finger the whole time
              if (_isDrawing && details.pointerCount == 1 && !_hadMultiplePointers) {
                _handleInteraction(details.localFocalPoint, false, isPortrait, width, height);
              }
            },
            onInteractionEnd: (details) {
              _isDrawing = false;
              _hadMultiplePointers = false;
            },
            child: Stack(
              children: [
                Flex(
                  direction: isPortrait ? Axis.vertical : Axis.horizontal,
                  children: [
                    Expanded(child: _buildSvgAsset('front')),
                    Expanded(child: _buildSvgAsset('back')),
                  ],
                ),
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
          );
        },
      ),
    );
  }

  void _handleInteraction(Offset localPoint, bool isStart, bool isPortrait, double width, double height) {
    final translatedPos = _getTranslatedPoint(localPoint);

    setState(() {
      if (isPortrait) {
        final midY = height / 2;
        if (translatedPos.dy < midY) {
          final point = Offset(translatedPos.dx / width, translatedPos.dy / midY);
          if (isStart) {
            _frontPaths.add([point]);
          } else if (_frontPaths.isNotEmpty && _isDrawing) {
            _frontPaths.last.add(point);
          }
        } else {
          final point = Offset(translatedPos.dx / width, (translatedPos.dy - midY) / midY);
          if (isStart) {
            _backPaths.add([point]);
          } else if (_backPaths.isNotEmpty && _isDrawing) {
            _backPaths.last.add(point);
          }
        }
      } else {
        final midX = width / 2;
        if (translatedPos.dx < midX) {
          final point = Offset(translatedPos.dx / midX, translatedPos.dy / height);
          if (isStart) {
            _frontPaths.add([point]);
          } else if (_frontPaths.isNotEmpty && _isDrawing) {
            _frontPaths.last.add(point);
          }
        } else {
          final point = Offset((translatedPos.dx - midX) / midX, translatedPos.dy / height);
          if (isStart) {
            _backPaths.add([point]);
          } else if (_backPaths.isNotEmpty && _isDrawing) {
            _backPaths.last.add(point);
          }
        }
      }
    });
  }

  Offset _getTranslatedPoint(Offset point) {
    final Matrix4 transform = _transformationController.value;
    final double scale = transform.getMaxScaleOnAxis();
    final double x = (point.dx - transform.storage[12]) / scale;
    final double y = (point.dy - transform.storage[13]) / scale;
    return Offset(x, y);
  }

  Widget _buildSvgAsset(String side) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SvgPicture.asset(
        'assets/body_maps/${side}_${_bodyType.name}.svg',
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn),
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
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

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
