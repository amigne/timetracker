import 'package:timezone/timezone.dart' as tz;

import '../models/setting.dart';

extension DateTimeExtension on DateTime {
  static Future<tz.TZDateTime> tzNow() async {
    final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';
    final appTz = tz.getLocation(timeZone);

    return tz.TZDateTime.from(DateTime.now(), appTz);
  }

  static Future<tz.TZDateTime> today() async {
    final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';
    final appTz = tz.getLocation(timeZone);

    final tzNow = await DateTimeExtension.tzNow();
    return tz.TZDateTime(appTz, tzNow.year, tzNow.month, tzNow.day);
  }
}
