import 'package:calddy/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:calddy/features/calendar/data/datasources/calendar_remote_datasource_impl.dart';
import 'package:calddy/features/calendar/data/datasources/drawing_remote_datasource.dart';
import 'package:calddy/features/calendar/data/datasources/drawing_remote_datasource_impl.dart';
import 'package:calddy/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:calddy/features/calendar/data/repositories/drawing_repository_impl.dart';
import 'package:calddy/features/calendar/domain/entities/calendar_data.dart';
import 'package:calddy/features/calendar/domain/entities/drawing_entity.dart';
import 'package:calddy/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:calddy/features/calendar/domain/repositories/drawing_repository.dart';
import 'package:calddy/features/calendar/domain/usecases/complete_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/create_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/create_habit_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/delete_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/get_calendar_by_month_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/get_calendar_by_week_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/get_drawing_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/save_drawing_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/upload_drawing_thumbnail_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/update_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/update_recurring_event_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Calendar ──────────────────────────────────────────────────────────────

// 1. DataSource
final calendarRemoteDataSourceProvider =
    Provider<CalendarRemoteDataSource>((ref) =>
        CalendarRemoteDataSourceImpl(Supabase.instance.client));

// 2. Repository
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) =>
    CalendarRepositoryImpl(
        remoteDataSource: ref.watch(calendarRemoteDataSourceProvider)));

// 3. UseCases
final getCalendarByMonthUseCaseProvider = Provider((ref) =>
    GetCalendarByMonthUseCase(ref.watch(calendarRepositoryProvider)));

final getCalendarByWeekUseCaseProvider = Provider((ref) =>
    GetCalendarByWeekUseCase(ref.watch(calendarRepositoryProvider)));

final createEventUseCaseProvider = Provider((ref) =>
    CreateEventUseCase(ref.watch(calendarRepositoryProvider)));

final createHabitUseCaseProvider = Provider((ref) =>
    CreateHabitUseCase(ref.watch(calendarRepositoryProvider)));

final updateEventUseCaseProvider = Provider((ref) =>
    UpdateEventUseCase(ref.watch(calendarRepositoryProvider)));

final updateRecurringEventUseCaseProvider = Provider((ref) =>
    UpdateRecurringEventUseCase(ref.watch(calendarRepositoryProvider)));

final deleteEventUseCaseProvider = Provider((ref) =>
    DeleteEventUseCase(ref.watch(calendarRepositoryProvider)));

final completeEventUseCaseProvider = Provider((ref) =>
    CompleteEventUseCase(ref.watch(calendarRepositoryProvider)));

// 4. 현재 선택된 월 상태
final selectedMonthProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

// 5. 월별 캘린더 데이터
final calendarDataProvider =
    FutureProvider.autoDispose<CalendarData>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(getCalendarByMonthUseCaseProvider);
  return useCase(GetCalendarByMonthParams(year: month.year, month: month.month));
});

// ── Drawing ───────────────────────────────────────────────────────────────

// 1. DataSource
final drawingRemoteDataSourceProvider =
    Provider<DrawingRemoteDataSource>((ref) =>
        DrawingRemoteDataSourceImpl(Supabase.instance.client));

// 2. Repository
final drawingRepositoryProvider = Provider<DrawingRepository>((ref) =>
    DrawingRepositoryImpl(
        remoteDataSource: ref.watch(drawingRemoteDataSourceProvider)));

// 3. UseCases
final saveDrawingUseCaseProvider = Provider((ref) =>
    SaveDrawingUseCase(ref.watch(drawingRepositoryProvider)));

final getDrawingUseCaseProvider = Provider((ref) =>
    GetDrawingUseCase(ref.watch(drawingRepositoryProvider)));

final uploadDrawingThumbnailUseCaseProvider = Provider((ref) =>
    UploadDrawingThumbnailUseCase(ref.watch(drawingRepositoryProvider)));

// 4. 선택된 날짜의 드로잉 조회
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final drawingByDateProvider =
    FutureProvider.autoDispose.family<DrawingEntity?, DateTime>((ref, date) {
  final useCase = ref.watch(getDrawingUseCaseProvider);
  return useCase(GetDrawingParams(date: date));
});

/// 해당 월의 드로잉 썸네일 URL 맵 (draw_date string → thumbnailUrl)
/// draw_date format: 'yyyy-MM-dd'
final drawingThumbnailsForMonthProvider = FutureProvider.autoDispose
    .family<Map<String, String?>, DateTime>((ref, month) {
  return ref
      .read(drawingRemoteDataSourceProvider)
      .getDrawingThumbnailsForMonth(month.year, month.month);
});
