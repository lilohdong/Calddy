import 'package:flutter/material.dart';

const kColorOptions = [
  '#7C6AFA', '#4CAF50', '#FF9800', '#9C27B0', '#F44336', '#FFC107',
];

// 최근 사용한 컬러 (최대 5개, 세션 유지)
final _recentColors = <String>[];

void _addRecentColor(String hex) {
  _recentColors.remove(hex);
  _recentColors.insert(0, hex);
  if (_recentColors.length > 5) _recentColors.removeLast();
}

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.options = kColorOptions,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> options;

  static Color fromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF7C6AFA);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Merge: recent (up to 3) + presets, deduplicated
    final allOptions = [
      ..._recentColors.take(3),
      ...options.where((h) => !_recentColors.contains(h)),
    ];

    return Row(
      children: [
        ...allOptions.take(6).map((hex) {
          final c = fromHex(hex);
          final isSelected = selected == hex;
          return GestureDetector(
            onTap: () {
              _addRecentColor(hex);
              onChanged(hex);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: c.computeLuminance() > 0.35
                          ? Colors.black87
                          : Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          );
        }),
        Builder(
          builder: (ctx) => GestureDetector(
            onTap: () async {
              final picked = await showDialog<String?>(
                context: ctx,
                builder: (_) => const _CustomColorDialog(),
              );
              if (picked != null) {
                _addRecentColor(picked);
                onChanged(picked);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog();
  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  final _hexCtrl = TextEditingController(text: '7C6AFA');
  String? _error;
  String? _selectedPaletteHex;

  // Predefined color palette (Material-inspired)
  static const _palette = [
    // Row 1: Purples/Blues
    '#6200EA', '#3D5AFE', '#2979FF', '#0091EA',
    // Row 2: Greens/Teals
    '#00BFA5', '#00C853', '#64DD17', '#AEEA00',
    // Row 3: Yellows/Oranges
    '#FFD600', '#FFAB00', '#FF6D00', '#DD2C00',
    // Row 4: Reds/Pinks
    '#D50000', '#C51162', '#AA00FF', '#6200EA',
    // Row 5: Darks/Neutrals
    '#263238', '#37474F', '#546E7A', '#90A4AE',
  ];

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  Color? _tryParseHex(String hex) {
    try {
      final clean = hex.replaceFirst('#', '').padLeft(6, '0');
      if (clean.length != 6) return null;
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = _tryParseHex(_hexCtrl.text);

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('색상 선택',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (previewColor != null)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: previewColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: previewColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Hex input
            TextField(
              controller: _hexCtrl,
              onChanged: (_) => setState(() => _error = null),
              maxLength: 7,
              decoration: InputDecoration(
                prefixText: '#',
                hintText: '7C6AFA',
                errorText: _error,
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF7F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7C6AFA)),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            // Color palette grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _palette.length,
              itemBuilder: (_, i) {
                final hex = _palette[i];
                final c = Color(int.parse(
                    hex.replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _hexCtrl.text = hex.replaceFirst('#', '');
                      _selectedPaletteHex = hex;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedPaletteHex == hex
                        ? Center(
                            child: Icon(
                              Icons.check,
                              color: c.computeLuminance() > 0.35
                                  ? Colors.black87
                                  : Colors.white,
                              size: 20,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('취소',
                        style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final hex = _hexCtrl.text.trim();
                      final color = _tryParseHex(hex);
                      if (color == null) {
                        setState(
                            () => _error = '올바른 색상 코드를 입력해주세요');
                        return;
                      }
                      final normalized =
                          '#${hex.replaceFirst('#', '').toUpperCase().padLeft(6, '0')}';
                      Navigator.of(context).pop(normalized);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6AFA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('적용'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
