
class DateTimeTZ {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final int microsecond;

  //final TZ tzinfo

  DateTimeTZ(this.year, this.month, this.day,
      [this.hour = 0, this.minute = 0, this.second = 0, this.microsecond = 0]);

}
  /*
  class datetime.datetime(year, month, day, hour=0, minute=0, second=0, microsecond=0, tzinfo=None, *, fold=0);

  classmethod datetime.today()
  classmethod datetime.now(tz=None)
  classmethod datetime.utcnow()
  classmethod datetime.fromtimestamp(timestamp, tz=None)
  classmethod datetime.utcfromtimestamp(timestamp)
  classmethod datetime.fromisoformat(date_string)

  datetime.year
  Between MINYEAR and MAXYEAR inclusive.

  datetime.month
  Between 1 and 12 inclusive.

  datetime.day
  Between 1 and the number of days in the given month of the given year.

  datetime.hour
  In range(24).

  datetime.minute
  In range(60).

  datetime.second
  In range(60).

  datetime.microsecond
  In range(1000000).

  datetime.tzinfo

  datetime.astimezone(tz=None)
*/