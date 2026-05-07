import 'package:calddy/core/usecase/usecase.dart';
import '../entities/calendar_data.dart';
import '../repositories/calendar_repository.dart';

class GetCalendarByWeekParams {
  final DateTime weekStart;
  const GetCalendarByWeekParams({required this.weekStart});
}

class GetCalendarByWeekUseCase
    implements UseCase<CalendarData, GetCalendarByWeekParams> {
  final CalendarRepository _repository;
  GetCalendarByWeekUseCase(this._repository);

  @override
  Future<CalendarData> call(GetCalendarByWeekParams params) =>
      _repository.getCalendarByWeek(params.weekStart);
}
