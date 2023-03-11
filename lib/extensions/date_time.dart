import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;



/*
extension StringFormating on DateTime {

  static String _fourDigits(int n) => (n < 0 ? '-' : '') + n.abs().toString().padLeft(4, '0');

  static String _sixDigits(int n) => (n < 0 ? '-' : '') + n.abs().toString().padLeft(6, '0');

  static String _threeDigits(int n) => n.toString().padLeft(3, '0');

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String toIso8601BasicString() {
    String y =
    (year >= -9999 && year <= 9999) ? _fourDigits(year) : _sixDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    String us = microsecond == 0 ? "" : _threeDigits(microsecond);
    if (isUtc) {
      return "$y-$m-${d}T$h:$min:$sec.$ms${us}Z";
    } else {
      return "$y-$m-${d}T$h:$min:$sec.$ms$us";
    }
  }
}
*/