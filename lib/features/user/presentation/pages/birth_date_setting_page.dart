import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/update_birth_date_use_case.dart';
import '../providers/user_providers.dart';
import '../widgets/profile_theme.dart';

class BirthDateSettingPage extends ConsumerStatefulWidget {
  const BirthDateSettingPage({super.key});

  @override
  ConsumerState<BirthDateSettingPage> createState() =>
      _BirthDateSettingPageState();
}

class _BirthDateSettingPageState
    extends ConsumerState<BirthDateSettingPage> {
  static const int _startYear = 1950;
  static final int _endYear   = DateTime.now().year;

  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;

  int _selectedYear  = 2000;
  int _selectedMonth = 1;
  int _selectedDay   = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile?.birthDate != null) {
      _selectedYear  = profile!.birthDate!.year;
      _selectedMonth = profile.birthDate!.month;
      _selectedDay   = profile.birthDate!.day;
    }
    _yearCtrl  = FixedExtentScrollController(initialItem: _selectedYear - _startYear);
    _monthCtrl = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _dayCtrl   = FixedExtentScrollController(initialItem: _selectedDay - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  void _onYearChanged(int i)  => setState(() => _selectedYear  = _startYear + i);
  void _onMonthChanged(int i) => setState(() => _selectedMonth = i + 1);
  void _onDayChanged(int i)   => setState(() => _selectedDay   = i + 1);

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(updateBirthDateUseCaseProvider).call(
            UpdateBirthDateParams(
              birthDate: DateTime(_selectedYear, _selectedMonth, _selectedDay),
            ),
          );
      ref.invalidate(currentUserProfileProvider);
      if (mounted) context.pop();
    } on UserFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('저장에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      appBar: AppBar(
        backgroundColor: ProfileTheme.bg,
        elevation: 0,
        centerTitle: true,
        title: const Text('생년월일 설정',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('정확한 생년월일을 입력해주세요.',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                '$_selectedYear. '
                '${_selectedMonth.toString().padLeft(2, '0')}. '
                '${_selectedDay.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ProfileTheme.primary),
              ),
              const SizedBox(height: 24),
              Container(
                height: 220,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: ProfileTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: ProfileTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _SpinnerCol(
                          controller: _yearCtrl,
                          count: _endYear - _startYear + 1,
                          label: (i) => '${_startYear + i}년',
                          selectedIdx: _selectedYear - _startYear,
                          onChanged: _onYearChanged,
                        ),
                        _SpinnerCol(
                          controller: _monthCtrl,
                          count: 12,
                          label: (i) => '${(i + 1).toString().padLeft(2, '0')}월',
                          selectedIdx: _selectedMonth - 1,
                          onChanged: _onMonthChanged,
                        ),
                        _SpinnerCol(
                          controller: _dayCtrl,
                          count: 31,
                          label: (i) => '${(i + 1).toString().padLeft(2, '0')}일',
                          selectedIdx: _selectedDay - 1,
                          onChanged: _onDayChanged,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline, size: 13, color: Color(0xFFBBBBBB)),
                    SizedBox(width: 4),
                    Text('생년월일은 변경에 제한이 있어요.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProfileTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('저장',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinnerCol extends StatelessWidget {
  const _SpinnerCol({
    required this.controller,
    required this.count,
    required this.label,
    required this.selectedIdx,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final String Function(int) label;
  final int selectedIdx;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (_, i) {
            final selected = i == selectedIdx;
            return Center(
              child: Text(
                label(i),
                style: TextStyle(
                  fontSize: selected ? 16 : 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? ProfileTheme.primary : const Color(0xFFBBBBBB),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
