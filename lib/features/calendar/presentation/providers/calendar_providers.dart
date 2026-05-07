import 'package:calddy/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:calddy/features/calendar/data/datasources/calendar_remote_datasource_impl.dart';
import 'package:calddy/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:calddy/features/calendar/domain/entities/calendar_data.dart';
import 'package:calddy/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:calddy/features/calendar/domain/usecases/complete_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/create_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/delete_event_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/get_calendar_by_month_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/get_calendar_by_week_usecase.dart';
import 'package:calddy/features/calendar/domain/usecases/update_event_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. DataSource
final calendarRemoteDataSourceProvider =
    Provider<CalendarRemoteDataSource>((ref) =>
        CalendarRemoteDataSourceImpl(Supabase.instance.client));

// 2. Repository
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) =>
    CalendarRepositoryImpl(
      remoteDataSource: ref.watch(calendarRemoteDataSourceProvider),
    ));

// 3. UseCases
final getCalendarByMonthUseCaseProvider = Provider((ref) =>
    GetCalendarByMonthUseCase(ref.watch(calendarRepositoryProvider)));

final getCalendarByWeekUseCaseProvider = Provider((ref) =>
    GetCalendarByWeekUseCase(ref.watch(calendarRepositoryProvider)));

final createEventUseCaseProvider = Provider((ref) =>
    CreateEventUseCase(ref.watch(calendarRepositoryProvider)));

final updateEventUseCaseProvider = Provider((ref) =>
    UpdateEventUseCase(ref.watch(calendarRepositoryProvider)));

final deleteEventUseCaseProvider = Provider((ref) =>
    DeleteEventUseCase(ref.watch(calendarRepositoryProvider)));

final completeEventUseCaseProvider = Provider((ref) =>
    CompleteEventUseCase(ref.watch(calendarRepositoryProvider)));

// 4. 현재 선택된 월 상태
final selectedMonthProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

// 5. 월별 캘린더 데이터 (UI가 watch)
final calendarDataProvider =
    FutureProvider.autoDispose<CalendarData>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(getCalendarByMonthUseCaseProvider);
  return useCase(GetCalendarByMonthParams(year: month.year, month: month.month));
});
