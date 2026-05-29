import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiMidpointPage extends StatefulWidget {
  const AiMidpointPage({super.key});

  @override
  State<AiMidpointPage> createState() => _AiMidpointPageState();
}

class _AiMidpointPageState extends State<AiMidpointPage> {
  String _calcBasis = '대중교통 최적화';
  int _selectedIndex = 0;

  static const _calcOptions = ['대중교통 최적화', '직선 거리', '도보 최적화'];

  static const _mockPlaces = [
    _MidpointPlace(rank: 1, name: '고속터미널역', lines: '3, 7, 9호선', avgMinutes: 30),
    _MidpointPlace(rank: 2, name: '강남구청역', lines: '7호선', avgMinutes: 32),
    _MidpointPlace(rank: 3, name: '신논현역', lines: '9호선', avgMinutes: 35),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AFA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '*AI',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7C6AFA),
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '중간지점 검색',
              style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              final place = _mockPlaces[_selectedIndex];
              context.pop(place.name);
            },
            child: const Text(
              '✓',
              style: TextStyle(
                  color: Color(0xFF7C6AFA),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 지도 플레이스홀더
          Container(
            height: 220,
            color: const Color(0xFFE8F0FE),
            child: Stack(
              children: [
                const Center(child: Text('🗺️', style: TextStyle(fontSize: 60))),
                Positioned(
                  left: 60,
                  bottom: 60,
                  child: _MapPin(label: '나·강남역', color: const Color(0xFF7C6AFA)),
                ),
                Positioned(
                  right: 60,
                  top: 40,
                  child: _MapPin(label: 'Friend(B)·잠실역', color: const Color(0xFFFF9800)),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C6AFA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '+ AI 추천 중간지점',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 하단 패널
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 참가자
                  const Text('참가자',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ParticipantChip(
                          initial: '나', label: '강남역', color: const Color(0xFF7C6AFA)),
                      const SizedBox(width: 8),
                      _ParticipantChip(
                          initial: 'B', label: '잠실역', color: const Color(0xFFFF9800)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 계산 기준
                  const Text('계산 기준',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _calcOptions.map((opt) {
                        final isSelected = _calcBasis == opt;
                        return GestureDetector(
                          onTap: () => setState(() => _calcBasis = opt),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7C6AFA)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 추천 중간지점
                  const Text('추천 중간지점',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  ..._mockPlaces.asMap().entries.map((e) {
                    final i = e.key;
                    final p = e.value;
                    final isSelected = _selectedIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7C6AFA).withValues(alpha: 0.08)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF7C6AFA), width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7C6AFA)
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${p.rank}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    '${p.lines} · 대중교통 이동 최적 (평균 ${p.avgMinutes}분)',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // 하단 버튼
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('이전으로',
                              style: TextStyle(color: Colors.black87)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final place = _mockPlaces[_selectedIndex];
                            context.pop(place.name);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C6AFA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('이 장소로 설정'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MidpointPlace {
  const _MidpointPlace({
    required this.rank,
    required this.name,
    required this.lines,
    required this.avgMinutes,
  });
  final int rank;
  final String name;
  final String lines;
  final int avgMinutes;
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
        Container(width: 2, height: 10, color: color),
      ],
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  const _ParticipantChip(
      {required this.initial, required this.label, required this.color});
  final String initial;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: color,
            child: Text(initial,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
