import 'package:flutter/material.dart';

extension DateTimeExtensions on DateTime {
  /// 두 DateTime이 같은 날짜인지 비교 (시간 무시)
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// 오늘 날짜인지 확인
  bool get isToday => isSameDay(DateTime.now());

  /// 'yyyy-MM-dd' 형식 문자열 반환
  String toDateString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

extension StringExtensions on String {
  /// 문자열이 비어있거나 공백만 있으면 true
  bool get isBlank => trim().isEmpty;

  /// null-safe 첫 글자 대문자
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

extension BuildContextExtensions on BuildContext {
  /// MediaQuery.of(context).size
  Size get screenSize => MediaQuery.of(this).size;

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// Theme.of(context)
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
}
