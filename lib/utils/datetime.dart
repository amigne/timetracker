import 'package:timezone/timezone.dart' as tz;

import '../models/setting.dart';

String format2digits(int n) => n.toString().padLeft(2, '0');

String format4digits(int n) => n.toString().padLeft(4, '0');

String formatDate(int year, int month, int day) =>
    '$year-${format2digits(month)}-${format2digits(day)}';

String formatMonth(int year, int month) => '$year-${format2digits(month)}';

String displayDuration(Duration duration) {
  final sign = duration.inMinutes < 0 ? '-' : '';
  final hours = format2digits(
      duration.inHours.abs() % 24); // In case we exceed 24 hours...
  final minutes = format2digits(duration.inMinutes.abs() % 60);

  return '$sign$hours:$minutes';
}

Future<String> displayTime(int utcTimestamp) async {
  final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';

  final appTz = tz.getLocation(timeZone);
  final appDateTime = tz.TZDateTime.from(
      DateTime.fromMillisecondsSinceEpoch(utcTimestamp, isUtc: true), appTz);

  final hours = format2digits(appDateTime.hour);
  final minutes = format2digits(appDateTime.minute);

  return '$hours:$minutes';
}
