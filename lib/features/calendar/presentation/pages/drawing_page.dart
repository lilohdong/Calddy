import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/drawing_entity.dart';
import '../../domain/usecases/save_drawing_usecase.dart';
import '../providers/calendar_providers.dart';
import '../widgets/color_picker_row.dart';
import '../widgets/sticker_grid_widget.dart';

class DrawingPage extends ConsumerStatefulWidget {
  const DrawingPage({super.key, required this.date});
  final String date;

  @override
  ConsumerState<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends ConsumerState<DrawingPage> {
  final _canvasKey = GlobalKey();
  final List<DrawingStroke> _strokes = [];
  List<List<double>> _currentPoints = [];
  Color _bgColor = const Color(0xFFE8E0FF);
  final Color _strokeColor = Colors.black87;
  final double _strokeWidth = 4.0;
  bool _handwritingMode = false;
  bool _isLoading = false;
  final List<_PlacedSticker> _stickers = [];
  bool _showStickerPanel = false;

  static const _bgColors = [
    Color(0xFFFFF9C4),
    Color(0xFFE8E0FF),
    Color(0xFFFFE0E0),
    Color(0xFFE0F7E9),
    Color(0xFF263238),
  ];

  static final _colorHexMap = <Color, String>{
    Colors.black87: '#1A1A1A',
    Colors.red: '#FF0000',
    Colors.blue: '#1565C0',
    Colors.green: '#2E7D32',
    Colors.orange: '#FF6D00',
    Colors.white: '#FFFFFF',
  };

  late final DateTime _date;

  @override
  void initState() {
    super.initState();
    final p = widget.date.split('-');
    _date = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  // 썸네일 캡처 → Storage 업로드 → 공개 URL 반환
  // 실패 시 throw (호출자가 에러 처리)
  Future<String> _captureAndUploadThumbnail(String userId) async {
    final ctx = _canvasKey.currentContext;
    if (ctx == null) throw Exception('캔버스 컨텍스트를 찾을 수 없습니다.');

    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('캔버스 RenderObject를 찾을 수 없습니다.');

    final image = await boundary.toImage(pixelRatio: 1.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('이미지 데이터 변환에 실패했습니다.');

    final bytes = byteData.buffer.asUint8List();
    final fileName = 'drawing_${userId}_${widget.date}.png';

    await Supabase.instance.client.storage
        .from('drawings')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );

    // 캐시 버스팅 타임스탬프 포함해서 반환 (NetworkImage 구버전 캐시 우회)
    final publicUrl = Supabase.instance.client.storage
        .from('drawings')
        .getPublicUrl(fileName);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final currentUserId =
          Supabase.instance.client.auth.currentUser?.id ?? '';

      // 썸네일 캡처·업로드 — 실패해도 드로잉 저장은 항상 진행
      String? thumbnailUrl;
      try {
        thumbnailUrl = await _captureAndUploadThumbnail(currentUserId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('썸네일 업로드 실패 (드로잉은 저장됩니다): $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // thumbnailUrl = null 로 저장 계속 진행
      }

      await ref.read(saveDrawingUseCaseProvider).call(
        SaveDrawingParams(
          drawing: DrawingEntity(
            id: '',
            userId: currentUserId,
            drawDate: _date,
            strokes: _strokes,
            thumbnailUrl: thumbnailUrl,
            updatedAt: now,
          ),
        ),
      );

      // 해당 월의 썸네일 provider를 명시적으로 무효화해 CalendarPage 즉시 갱신
      final month = DateTime(_date.year, _date.month);
      ref.invalidate(drawingThumbnailsForMonthProvider(month));
      ref.invalidate(calendarDataProvider);

      if (mounted) context.pop();
    } on DrawingFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('저장에 실패했습니다.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final isDark = _bgColor.computeLuminance() < 0.3;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '꾸미기',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(
                    '저장',
                    style: TextStyle(
                        color: Color(0xFF7C6AFA), fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 캔버스
          Expanded(
            child: GestureDetector(
              onPanStart: _handwritingMode
                  ? (details) {
                      setState(() {
                        _currentPoints = [
                          [details.localPosition.dx, details.localPosition.dy]
                        ];
                      });
                    }
                  : null,
              onPanUpdate: _handwritingMode
                  ? (details) {
                      _currentPoints.add(
                          [details.localPosition.dx, details.localPosition.dy]);
                      setState(() {});
                    }
                  : null,
              onPanEnd: _handwritingMode
                  ? (_) {
                      if (_currentPoints.isNotEmpty) {
                        final hex = _colorHexMap[_strokeColor] ??
                            '#${_strokeColor.toARGB32().toRadixString(16).padLeft(8, '0')}';
                        setState(() {
                          _strokes.add(DrawingStroke(
                            color: hex,
                            width: _strokeWidth,
                            points: List.from(_currentPoints),
                          ));
                          _currentPoints = [];
                        });
                      }
                    }
                  : null,
              child: RepaintBoundary(
                key: _canvasKey,
                child: Container(
                  color: _bgColor,
                  child: Stack(
                  children: [
                    // 날짜 표시
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_date.day}',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              height: 1,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : const Color(0xFF7C6AFA),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${weekdays[_date.weekday % 7]}요일',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.55)
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 배치된 스티커
                    ..._stickers.map((s) => Positioned(
                          left: s.x,
                          top: s.y,
                          child: GestureDetector(
                            onPanUpdate: (d) {
                              setState(() {
                                s.x += d.delta.dx;
                                s.y += d.delta.dy;
                              });
                            },
                            child: Text(s.emoji,
                                style: const TextStyle(fontSize: 36)),
                          ),
                        )),
                    // 손글씨 캔버스 (IgnorePointer로 감싸 스티커 드래그 가능)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _CanvasPainter(
                          strokes: _strokes,
                          currentPoints: _currentPoints,
                          currentColor: _strokeColor,
                          currentWidth: _strokeWidth,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
          // 하단 툴패널
          _BottomToolPanel(
            bgColors: _bgColors,
            selectedBg: _bgColor,
            onBgChanged: (c) => setState(() => _bgColor = c),
            onBgColorCustom: () async {
              final picked = await showDialog<String?>(
                context: context,
                builder: (_) => const CustomColorDialog(),
              );
              if (picked != null && mounted) {
                setState(() => _bgColor = ColorPickerRow.fromHex(picked));
              }
            },
            handwritingMode: _handwritingMode,
            onHandwritingToggle: (v) => setState(() {
              _handwritingMode = v;
              if (!v) _currentPoints = [];
            }),
            showStickerPanel: _showStickerPanel,
            onStickerToggle: () =>
                setState(() => _showStickerPanel = !_showStickerPanel),
            onStickerSelected: (emoji) {
              setState(() {
                _stickers.add(_PlacedSticker(
                  emoji: emoji,
                  x: 100 + (_stickers.length * 20) % 200,
                  y: 100 + (_stickers.length * 15) % 150,
                ));
                _showStickerPanel = false;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _PlacedSticker {
  _PlacedSticker({required this.emoji, required this.x, required this.y});
  final String emoji;
  double x;
  double y;
}

class _BottomToolPanel extends StatelessWidget {
  const _BottomToolPanel({
    required this.bgColors,
    required this.selectedBg,
    required this.onBgChanged,
    required this.onBgColorCustom,
    required this.handwritingMode,
    required this.onHandwritingToggle,
    required this.showStickerPanel,
    required this.onStickerToggle,
    required this.onStickerSelected,
  });

  final List<Color> bgColors;
  final Color selectedBg;
  final ValueChanged<Color> onBgChanged;
  final VoidCallback onBgColorCustom;
  final bool handwritingMode;
  final ValueChanged<bool> onHandwritingToggle;
  final bool showStickerPanel;
  final VoidCallback onStickerToggle;
  final ValueChanged<String> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStickerPanel)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('스티커',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  StickerGridWidget(onStickerSelected: onStickerSelected),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('배경',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...bgColors.map((c) => GestureDetector(
                          onTap: () => onBgChanged(c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(8),
                              border: selectedBg == c
                                  ? Border.all(
                                      color: const Color(0xFF7C6AFA),
                                      width: 2)
                                  : Border.all(
                                      color: Colors.grey.shade200),
                            ),
                          ),
                        )),
                    // + 커스텀 컬러
                    GestureDetector(
                      onTap: onBgColorCustom,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.add,
                            size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: const Text('기타',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('손글씨',
                            style: TextStyle(fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                    Switch(
                      value: handwritingMode,
                      onChanged: onHandwritingToggle,
                      activeThumbColor: const Color(0xFF7C6AFA),
                    ),
                  ],
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emoji_emotions_outlined,
                      size: 18, color: Colors.black54),
                  title: const Text('스티커', style: TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: onStickerToggle,
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
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
        c = Colors.black87;
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
