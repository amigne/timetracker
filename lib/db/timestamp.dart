class Timestamp {
  final int? id;
  late final DateTime dateTime;
  late final Duration localTimeZone;
  final int inputType;
  final bool deleted;

  static const inputClick = 0;
  static const inputManual = 1;

  Timestamp(DateTime dateTime,
      { this.id, Duration? localTimeZone, this.inputType = inputClick, this.deleted = false}) {
    this.localTimeZone = localTimeZone ?? dateTime.timeZoneOffset;
    this.dateTime = dateTime.toUtc();
  }

  Timestamp.fromDateAndTime(String utcDate, String utcTime,
      {this.id, String? localTimeZone, this.inputType = inputClick,
        this.deleted = false}) {
    var

  }

/*  Timestamp.fromDatetime({this.id, required DateTime dateTime, this.inputType = inputClick, this.deleted = false}) :
        date = formatDate(dateTime.year, dateTime.month, dateTime.day),
        time = formatTime(dateTime.hour, dateTime.minute),
        timeZone = formatTimeZone(dateTime.timeZoneOffset);
 */

  static String formatDate(int year, int month, int day) =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(
          2, '0')}-${day.toString().padLeft(2, '0')}';

  static String formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static String formatTimeZone(Duration timeZone) {
    var sign = timeZone.inHours >= 0 ? '+' : '−';
    var hour = timeZone.inHours.abs() %
        24; // % 24 shouldn't be necessary, but... who knows
    var minute = timeZone.inMinutes.abs() % 60;

    return '$sign${formatTime(hour, minute)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'inputType': inputType,
      'deleted': deleted,
    };
  }
}
