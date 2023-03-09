import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


extension DateTimeExtension on DateTime {
  static int _estToUtcDifference == null;

  int _getESTtoUTCDifference() {
    if (_estToUtcDifference == null) {
      tz.initializeTimeZones();
      final locationNY = tz.getLocation('America/New_York');
      tz.TZDateTime nowNY = tz.TZDateTime.now(locationNY);
      _estToUtcDifference = nowNY.timeZoneOffset.inHours;
    }

    return _estToUtcDifference;
  }

  DateTime toESTzone() {
    DateTime result = this.toUtc(); // local time to UTC
    result = result.add(Duration(hours: _getESTtoUTCDifference())); // convert UTC to EST
    return result;
  }

  DateTime fromESTzone() {
    DateTime result = this.subtract(Duration(hours: _getESTtoUTCDifference())); // convert EST to UTC

    String dateTimeAsIso8601String = result.toIso8601String();
    dateTimeAsIso8601String += dateTimeAsIso8601String.characters.last.equalsIgnoreCase('Z') ? '' : 'Z';
    result = DateTime.parse(dateTimeAsIso8601String); // make isUtc to be true

    result = result.toLocal(); // convert UTC to local time
    return result;
  }
}


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