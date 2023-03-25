import 'package:timezone/timezone.dart' as tz;

import '../models/setting.dart';
import '../models/timestamp.dart';
import '../utils/datetime.dart';

extension TimestampExtension on Timestamp {
  static Future<void> addTimestamp(
      {int? timestamp,
      int? utcTimestamp,
      Object? origin,
      Object? deleted}) async {
    if (timestamp != null) {
      if (utcTimestamp != null) {
        throw ArgumentError('timestamp cannot be used with utcTimestamp');
      }
      utcTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp)
          .toUtc()
          .millisecondsSinceEpoch;
    }
    if (origin != null) {
      if (origin is int || origin is TimestampsOrigin) {
        origin = origin is int ? origin : (origin as TimestampsOrigin).index;
      } else {
        throw ArgumentError(
            'origin, when specified, must either be an int or a TimestampsOrigin enumeration value.');
      }
    }
    if (deleted != null && deleted is! bool && deleted is! int) {
      throw ArgumentError(
          'deleted, when specified, must either be an int or a bool value.');
    }

    utcTimestamp ??= DateTime.now().toUtc().millisecondsSinceEpoch;
    deleted ??= 0;

    final Timestamp timestampObject = Timestamp(
        utcTimestamp: Timestamp.normalizeTimestamp(utcTimestamp),
        origin: origin as int?,
        deleted: deleted is int ? deleted : ((deleted as bool) ? 1 : 0));

    await timestampObject.save();
  }

  static Future<List<Timestamp>> listTodayActiveTimestamps() async {
    final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';

    final appTz = tz.getLocation(timeZone);
    final now = tz.TZDateTime.from(DateTime.now(), appTz);

    // Determine both timestamps at midnight
    final utcTimestampMin = tz.TZDateTime(appTz, now.year, now.month, now.day)
        .toUtc()
        .millisecondsSinceEpoch;
    final utcTimestampMax =
        tz.TZDateTime(appTz, now.year, now.month, now.day + 1)
            .toUtc()
            .millisecondsSinceEpoch;

    return await Timestamp.query(
        utcTimestampMin: utcTimestampMin,
        utcTimestampMax: utcTimestampMax,
        deleted: false);
  }

  static Future<int> countTodayActiveTimestamps() async {
    return (await listTodayActiveTimestamps()).length;
  }

  static Future<List> listTimestampsSingleDay(int year, int month, int day,
      {bool includeDeleted = false}) async {
    final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';

    final appTz = tz.getLocation(timeZone);

    final utcTimestampMin =
        tz.TZDateTime(appTz, year, month, day).toUtc().millisecondsSinceEpoch;
    final utcTimestampMax = tz.TZDateTime(appTz, year, month, day + 1)
        .toUtc()
        .millisecondsSinceEpoch;

    return await Timestamp.query(
        utcTimestampMin: utcTimestampMin,
        utcTimestampMax: utcTimestampMax,
        deleted: includeDeleted ? null : false);
  }

  static Future<Duration> getTotalDuration(
      [int? year, int? month, int? day]) async {
    final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';

    final appTz = tz.getLocation(timeZone);
    final now = tz.TZDateTime.from(DateTime.now(), appTz);

    year = year ?? now.year;
    month = month ?? now.month;
    day = day ?? now.day;

    final timestamps = await listTimestampsSingleDay(year, month, day);
    final count = timestamps.length;
    if (count <= 0) {
      return const Duration();
    }

    List<int> times =
        timestamps.map((timestamp) => timestamp.utcTimestamp as int).toList();
    if (count % 2 == 1) {
      // Add current time to have an even number of records
      final time = now.toUtc().millisecondsSinceEpoch;
      times.insert(0, time);
    }

    int totalTime = 0;
    for (int i = 0; i < count; i += 2) {
      totalTime += (times[i] - times[i + 1]);
    }

    return Duration(milliseconds: totalTime);
  }

  static Future<String> getWeekDayString([int? weekday]) async {
    Map<int, String> weekDayString = {
      DateTime.monday: 'monday',
      DateTime.tuesday: 'tuesday',
      DateTime.wednesday: 'wednesday',
      DateTime.thursday: 'thursday',
      DateTime.friday: 'friday',
      DateTime.saturday: 'saturday',
      DateTime.sunday: 'sunday',
    };

    if (weekday == null) {
      final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';

      final appTz = tz.getLocation(timeZone);
      weekday = tz.TZDateTime.from(DateTime.now().toUtc(), appTz).weekday;
    }
    return weekDayString[weekday] ?? 'unknown';
  }

  static Future<Timestamp?> getLastTimestamp() async {
    final todayTimestamps = await listTodayActiveTimestamps();
    return todayTimestamps.isNotEmpty ? todayTimestamps[0] : null;
  }

  static Future<Timestamp?> getFirstTimestamp() async {
    final firstTimestamp = await Timestamp.query(orderDesc: false, limit: 1);
    return firstTimestamp.isNotEmpty ? firstTimestamp[0] : null;
  }

  static Future<String> displayTime(int utcTimestamp) async {
    final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';

    final appTz = tz.getLocation(timeZone);
    final appDateTime = tz.TZDateTime.from(
        DateTime.fromMillisecondsSinceEpoch(utcTimestamp, isUtc: true), appTz);

    final hours = format2digits(appDateTime.hour);
    final minutes = format2digits(appDateTime.minute);

    return '$hours:$minutes';
  }

  static Future<List<String>> getListOfMonths() async {
    final timestamps = await Timestamp.query(orderDesc: false, limit: 1);
    final beginning = timestamps.isNotEmpty
        ? DateTime.fromMillisecondsSinceEpoch(timestamps[0].utcTimestamp,
            isUtc: true)
        : DateTime.now().toUtc();
    final end = DateTime.now().toUtc();

    List<String> months = [];
    for (var year = end.year; year >= beginning.year; --year) {
      final startMonth = (year == end.year ? end.month : 12);
      final endMonth = (year == beginning.year ? beginning.month : 1);
      for (var month = startMonth; month >= endMonth; --month) {
        months.add('${format4digits(year)}-${format2digits(month)}');
      }
    }

    return months;
  }
}
