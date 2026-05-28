import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/place_entity.dart';
import '../providers/map_providers.dart';

/// 장소 선택 페이지
/// - appointmentId가 있으면: 중간지점 계산 → 추천 장소 목록 표시
/// - appointmentId가 없으면: 수동 텍스트 입력으로 장소 선택
/// 선택 완료 시 context.pop(PlaceEntity?) 로 결과 반환
class PlacePickerPage extends ConsumerWidget {
  const PlacePickerPage({super.key, this.appointmentId});

  final String? appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('장소 선택')),
      body: appointmentId != null
          ? _RecommendedPlaces(appointmentId: appointmentId!)
          : const _ManualPicker(),
    );
  }
}

// ── 추천 장소 (약속 기반) ──────────────────────────────────────────────────────

class _RecommendedPlaces extends ConsumerWidget {
  const _RecommendedPlaces({required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final midpointAsync = ref.watch(midpointProvider(appointmentId));

    return midpointAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('중간지점 계산 중...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(e.toString(), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const _ManualPicker(),
          ],
        ),
      ),
      data: (midpoint) {
        final recommendAsync = ref.watch(recommendPlaceProvider(midpoint));

        return Column(
          children: [
            // 중간지점 정보 카드
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, color: Colors.deepPurple.shade400, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        '계산된 중간지점',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'lat: ${midpoint.lat.toStringAsFixed(5)}, lng: ${midpoint.lng.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // 참가자별 이동시간
                  ...midpoint.participants.map((p) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              p.nickname,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              p.travelMinutes != null
                                  ? '약 ${p.travelMinutes}분'
                                  : '이동시간 미정',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            // 추천 장소 목록
            Expanded(
              child: recommendAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(e.toString(),
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                data: (result) {
                  if (result.places.isEmpty) {
                    return const Center(
                      child: Text('추천 장소를 찾지 못했습니다.',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          '추천 키워드: ${result.recommendedKeyword}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: result.places.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _PlaceTile(
                            place: result.places[i],
                            onTap: () => context.pop(result.places[i]),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 수동 입력 ──────────────────────────────────────────────────────────────────

class _ManualPicker extends StatefulWidget {
  const _ManualPicker();

  @override
  State<_ManualPicker> createState() => _ManualPickerState();
}

class _ManualPickerState extends State<_ManualPicker> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    context.pop(PlaceEntity(
      placeId: '',
      name: name,
      address: '',
      lat: 0,
      lng: 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 48, color: Colors.deepPurple),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
            decoration: const InputDecoration(
              labelText: '장소명 입력',
              hintText: '예) 강남역 스타벅스',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('선택'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 장소 타일 ──────────────────────────────────────────────────────────────────

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});

  final PlaceEntity place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.place,
                  color: Colors.deepPurple.shade400, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.address,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (place.distanceFromMidpoint != null) ...[
              const SizedBox(width: 8),
              Text(
                '${(place.distanceFromMidpoint! / 1000).toStringAsFixed(1)}km',
                style:
                    const TextStyle(fontSize: 12, color: Colors.deepPurple),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
