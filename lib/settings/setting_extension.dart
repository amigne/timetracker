import 'package:timetracker/timestamps/timestamp_extension.dart';

import '../models/setting.dart';
import '../timestamps/datetime_extension.dart';

extension SettingExtension on Setting {
  static Future<DateTime> startDate() async {
    final settingStartTimestamp = await Setting.get('general.startTimestamp');

    late int startTimestamp;
    if (settingStartTimestamp != null) {
      startTimestamp = int.parse(settingStartTimestamp);
    } else {
      final firstTimestamp = await TimestampExtension.getFirstTimestamp();
      if (firstTimestamp != null) {
        startTimestamp = firstTimestamp.utcTimestamp;
      } else {
        startTimestamp =
            (await DateTimeExtension.today()).toUtc().millisecondsSinceEpoch;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(startTimestamp, isUtc: true);
  }

  static Future<int> getStandardWorkDurationForDay([int? weekday]) async {
    final weekDayString = await TimestampExtension.getWeekDayString(weekday);
    return int.parse((await Setting.get('duration.due.$weekDayString')) ?? '0');
  }

  static Future<int> getMaximumWorkDurationForDay([int? weekday]) async {
    final weekDayString = await TimestampExtension.getWeekDayString(weekday);
    return int.parse((await Setting.get('duration.max.$weekDayString')) ?? '0');
  }
}
