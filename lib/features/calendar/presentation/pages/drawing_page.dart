import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/drawing_entity.dart';
import '../../domain/usecases/save_drawing_usecase.dart';
import '../providers/calendar_providers.dart';

class DrawingPage extends ConsumerStatefulWidget {
  const DrawingPage({super.key, required this.date});
  final String date; // 'yyyy-MM-dd'

  @override
  ConsumerState<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends ConsumerState<DrawingPage> {
  final List<DrawingStroke> _strokes = [];
  List<List<double>> _currentPoints = [];
  Color _selectedColor = Colors.deepPurple;
  double _strokeWidth = 4.0;
  bool _isLoading = false;

  static const _colors = [
    Colors.deepPurple,
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.white,
  ];

  static final _colorHexMap = {
    Colors.deepPurple: '#7C6AFA',
    Colors.black: '#000000',
    Colors.red: '#FF0000',
    Colors.green: '#00AA00',
    Colors.orange: '#FFA500',
    Colors.white: '#FFFFFF',
  };

  DateTime get _parsedDate {
    final parts = widget.date.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      await ref.read(saveDrawingUseCaseProvider).call(
            SaveDrawingParams(
              drawing: DrawingEntity(
                id: '',
                userId: '',
                drawDate: _parsedDate,
                strokes: _strokes,
                updatedAt: now,
              ),
            ),
          );
      if (mounted) context.pop();
    } on DrawingFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('저장에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final d = _parsedDate;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('${d.month}월 ${d.day}일 드로잉'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _strokes.clear()),
            child: const Text('초기화'),
          ),
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 캔버스
          Expanded(
            child: GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _currentPoints = [
                    [d.localPosition.dx, d.localPosition.dy]
                  ];
                });
              },
              onPanUpdate: (d) {
                setState(() {
                  _currentPoints = [
                    ..._currentPoints,
                    [d.localPosition.dx, d.localPosition.dy],
                  ];
                });
              },
              onPanEnd: (_) {
                if (_currentPoints.isNotEmpty) {
                  final hex = _colorHexMap[_selectedColor] ??
                      '#${_selectedColor.value.toRadixString(16).padLeft(8, '0')}';
                  setState(() {
                    _strokes.add(DrawingStroke(
                      color: hex,
                      width: _strokeWidth,
                      points: List.from(_currentPoints),
                    ));
                    _currentPoints = [];
                  });
                }
              },
              child: CustomPaint(
                painter: _CanvasPainter(
                  strokes: _strokes,
                  currentPoints: _currentPoints,
                  currentColor: _selectedColor,
                  currentWidth: _strokeWidth,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // 하단 도구
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // 색상 팔레트
                for (final c in _colors)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _selectedColor == c
                            ? Border.all(color: Colors.deepPurple, width: 3)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                const Spacer(),
                // 굵기
                const Icon(Icons.line_weight, color: Colors.grey, size: 18),
                Slider(
                  value: _strokeWidth,
                  min: 2,
                  max: 16,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                  activeColor: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  const _CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  final List<DrawingStroke> strokes;
  final List<List<double>> currentPoints;
  final Color currentColor;
  final double currentWidth;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      Color c;
      try {
        c = Color(int.parse(s.color.replaceFirst('#', '0xFF')));
      } catch (_) {
        c = Colors.deepPurple;
      }
      _drawPoints(canvas, s.points, c, s.width);
    }
    if (currentPoints.isNotEmpty) {
      _drawPoints(canvas, currentPoints, currentColor, currentWidth);
    }
  }

  void _drawPoints(
      Canvas canvas, List<List<double>> pts, Color color, double width) {
    if (pts.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pts[0][0], pts[0][1]);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i][0], pts[i][1]);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}
