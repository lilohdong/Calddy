import 'package:calddy/core/usecase/usecase.dart';
import '../entities/calendar_data.dart';
import '../repositories/calendar_repository.dart';

class GetCalendarByMonthParams {
  final int year;
  final int month;
  const GetCalendarByMonthParams({required this.year, required this.month});
}

class GetCalendarByMonthUseCase
    implements UseCase<CalendarData, GetCalendarByMonthParams> {
  final CalendarRepository _repository;
  GetCalendarByMonthUseCase(this._repository);

  @override
  Future<CalendarData> call(GetCalendarByMonthParams params) =>
      _repository.getCalendarByMonth(params.year, params.month);
}
