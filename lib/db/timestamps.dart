import 'dart:io';
import 'dart:core';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;

import '../settings/settings.dart';
import 'timestamp.dart';

// TODO: THE COMPLETE CONTENT OF THIS FILE MUST BE DEEPLY REFACTORED

dynamic timestampDatabase;

dynamic getTimestampDatabase() async {
  return timestampDatabase ?? await openTimestampDatabase();
}

Future<String> getDatabasesPath() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  return await databaseFactory.getDatabasesPath();
}

dynamic openTimestampDatabase({String filename = 'timestamps.db'}) async {
  if (timestampDatabase == null) {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    timestampDatabase = await databaseFactory.openDatabase(
      join(await databaseFactory.getDatabasesPath(), filename),
      options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreateTimestampDatabase,
          onDowngrade: onDatabaseDowngradeDelete),
    );
  }

  return timestampDatabase;
}

void _onCreateTimestampDatabase(db, version) async {
  var batch = db.batch();
  _createTableTimestampV1(batch);
  await _createTableSettingsV1(batch);
  _fillTableSettingsV1(batch);
  await batch.commit();
}

void _createTableTimestampV1(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS Timestamps');
  batch.execute('CREATE TABLE Timestamps ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'dateTime INTEGER, '
      'origin INTEGER, '
      'deleted INTEGER'
      ')');
}

Future<void> _createTableSettingsV1(Batch batch) async {
  batch.execute('DROP TABLE IF EXISTS Settings');
  batch.execute('CREATE TABLE Settings ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'key TEXT, '
      'value TEXT'
      ')');
}

void _fillTableSettingsV1(Batch batch) {
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("general.timeZone", "Europe/Zurich")');
  final now = DateTime.now();
  final todayTimestamp = DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch;
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("general.startTimestamp", "$todayTimestamp")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.mondays", "492")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.tuesdays", "492")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.wednesdays", "492")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.thursdays", "492")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.fridays", "492")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.saturdays", "0")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.sundays", "0")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.max.mondays", "660")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.max.tuesdays", "660")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.max.wednesdays", "660")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.max.thursdays", "660")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.max.fridays", "660")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.max.saturdays", "0")');
  batch.execute(
      'INSERT INTO Settings (key, value) VALUES ("duration.max.sundays", "0")');
}

class AlreadySameTimestampException implements Exception {}

Future<void> addTimestamp({required Timestamp timestamp}) async {
  final database = await getTimestampDatabase();

  // First query: Ensure there is no timestamp at the same instant
  var query = 'SELECT dateTime FROM Timestamps WHERE dateTime=?';
  var queryValues = [
    timestamp.millisecondsSinceEpoch,
  ];
  var result = await database.rawQuery(query, queryValues);

  if (result.length > 0) {
    throw AlreadySameTimestampException();
  }

  await database.insert('Timestamps', timestamp.toMapForDB());
}

Future<void> deleteTimestamp(int id) async {
  final database = await getTimestampDatabase();

  await database.update(
      'Timestamps',
      {'deleted': 1},
      where: 'id = ?',
      whereArgs: [id]);
}

Future<void> undeleteTimestamp(int id) async {
  final database = await getTimestampDatabase();

  await database.update(
      'Timestamps',
      {'deleted': 0},
      where: 'id = ?',
      whereArgs: [id]);
}

Future<List> listAllTimestamps() async {
  var database = await getTimestampDatabase();

  var query = 'SELECT * FROM Timestamps';
  var values = [];
  return await database.rawQuery(query, values);
}

Future<int> getUtcMidnightForTZ(int year, int month, int day) async {
  final settings = await Settings.instance();
  final timeZone = settings.settings['general.timeZone'] ?? 'UTC';

  final appTZ = tz.getLocation(timeZone);
  final dateTime = tz.TZDateTime(appTZ, year, month, day).toUtc();

  return dateTime.millisecondsSinceEpoch;
}

Future<List> listTimestampsSingleDay(int year, int month, int day,
    {bool includeDeleted = false}) async {
  var database = await getTimestampDatabase();

  var query =
      'SELECT * FROM Timestamps WHERE dateTime>=? AND dateTime <? ${!includeDeleted ? 'AND deleted=? ' : ''}ORDER BY dateTime DESC';
  var values = [
    await getUtcMidnightForTZ(year, month, day),
    await getUtcMidnightForTZ(year, month, day + 1),
  ];
  if (!includeDeleted) {
    values.add(0);
  }
  return await database.rawQuery(query, values);
}

Future<tz.TZDateTime> tzNow() async {
  final settings = await Settings.instance();
  final timeZone = settings.settings['general.timeZone'] ?? 'UTC';
  final appTz = tz.getLocation(timeZone);

  return tz.TZDateTime.from(DateTime.now(), appTz);
}

Future<List> listTodayActiveTimestamps() async {
  var settings = await Settings.instance();
  var timeZone = settings.settings['general.timeZone'] ?? 'UTC';

  var appTz = tz.getLocation(timeZone);
  var now = tz.TZDateTime.from(DateTime.now(), appTz);

  return await listTimestampsSingleDay(now.year, now.month, now.day,
      includeDeleted: false);
}

Future<int> countTodayActiveTimestamps() async {
  return (await listTodayActiveTimestamps()).length;
}

String _formatTime(int hour, int minute) =>
    'T${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}';

String formatDate(int year, int month, int day) =>
    '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

Future<int> getLastTimestamp() async {
  var todayTimestamps = await listTodayActiveTimestamps();
  return todayTimestamps.isNotEmpty ? todayTimestamps[0]['dateTime'] : -1;
}

Future<DateTime> getStartDate() async {
  final settings = await Settings.instance();
  // TODO: Default value: use first timestamp instead of current date
  final startTimestamp = int.parse(settings.settings['general.startTimestamp'] ?? ((await tzNow()).millisecondsSinceEpoch).toString());

  return DateTime.fromMillisecondsSinceEpoch(startTimestamp);
}

Future<Duration> getTotalDuration([int? year, int? month, int? day]) async {
  var settings = await Settings.instance();
  var timeZone = settings.settings['general.timeZone'] ?? 'UTC';

  var appTz = tz.getLocation(timeZone);
  var now = tz.TZDateTime.from(DateTime.now(), appTz);

  year = year ?? now.year;
  month = month ?? now.month;
  day = day ?? now.day;

  var resultSet = await listTimestampsSingleDay(year, month, day);
  var count = resultSet.length;
  if (count <= 0) {
    return const Duration();
  }

  List<int> times = resultSet.map((dict) => dict['dateTime'] as int).toList();
  if (count % 2 == 1) {
    // Add current time to have an even number of records
    var time = now.millisecondsSinceEpoch;
    times.insert(0, time);
  }

  int totalTime = 0;
  for (int i = 0; i < count; i += 2) {
    totalTime += (times[i] - times[i + 1]);
  }

  return Duration(milliseconds: totalTime);
}

double getTimeStringToDouble(String time) {
  var hour = int.parse(time.substring(1, 3));
  var minutes = int.parse(time.substring(3, 5));

  return hour + (minutes / 60);
}

String getTimeDoubleToString(double time) {
  var hour = time.truncate();
  var minutes = (time - hour) * 60;

  return _formatTime(hour, minutes.round());
}

String displayDuration(Duration duration) {
  var sign = duration.inMinutes < 0 ? '-' : '';
  var hours = (duration.inHours.abs() % 24)
      .toString()
      .padLeft(2, '0'); // In case we exceed 24 hours...
  var minutes = (duration.inMinutes.abs() % 60).toString().padLeft(2, '0');

  return '$sign$hours:$minutes';
}

Future<String> displayTime(int millisecondsSinceEpoch) async {
  var settings = await Settings.instance();
  var timeZone = settings.settings['general.timeZone'] ?? 'UTC';

  var appTz = tz.getLocation(timeZone);
  var appDateTime = tz.TZDateTime.from(
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true),
      appTz);

  var hours = appDateTime.hour
      .toString()
      .padLeft(2, '0'); // In case we exceed 24 hours...
  var minutes = appDateTime.minute.toString().padLeft(2, '0');

  return '$hours:$minutes';
}

Future<String> getWeekDayString([int? weekday]) async {
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
    var settings = await Settings.instance();
    var timeZone = settings.settings['general.timeZone'] ?? 'UTC';

    var appTz = tz.getLocation(timeZone);
    weekday = tz.TZDateTime.from(DateTime.now().toUtc(), appTz).weekday;
  }
  return weekDayString[weekday] ?? 'unknown';
}

Future<String> getTodayWeekDay() async {
  Map<int, String> weekDayString = {
    DateTime.monday: 'monday',
    DateTime.tuesday: 'tuesday',
    DateTime.wednesday: 'wednesday',
    DateTime.thursday: 'thursday',
    DateTime.friday: 'friday',
    DateTime.saturday: 'saturday',
    DateTime.sunday: 'sunday',
  };

  var settings = await Settings.instance();
  var timeZone = settings.settings['general.timeZone'] ?? 'UTC';

  var appTz = tz.getLocation(timeZone);
  var appDateTime = tz.TZDateTime.from(DateTime.now().toUtc(), appTz);

  return weekDayString[appDateTime.weekday] ?? 'unknown';
}

Future<List<String>> getListOfMonths() async {
  var database = await getTimestampDatabase();

  var query =
      'SELECT * FROM Timestamps WHERE deleted=? ORDER BY dateTime ASC LIMIT 1';
  var values = [0];
  List<Map> result = await database.rawQuery(query, values);

  var beginning = result.isNotEmpty
      ? DateTime.fromMillisecondsSinceEpoch(result[0]['dateTime'])
      : DateTime.now();
  var end = DateTime.now();

  List<String> months = [];
  for (var year = end.year; year >= beginning.year; --year) {
    var startMonth = (year == end.year ? end.month : 12);
    var endMonth = (year == beginning.year ? beginning.month : 1);
    for (var month = startMonth; month >= endMonth; --month) {
      months.add('${formatYear(year)}-${formatMonth(month)}');
    }
  }

  return months;
}

String formatMonth(int month) => month.toString().padLeft(2, '0');
String formatYear(int year) => year.toString().padLeft(4, '0');

Future<int> getStandardWorkDurationForDay([int? weekday]) async {
  var weekDayString = await getWeekDayString(weekday);

  var settings = await Settings.instance();
  return int.parse(settings.settings['duration.${weekDayString}s'] ?? '0');
}

Future<int> getMaximumWorkDurationForDay([int? weekday]) async {
  var weekDayString = await getWeekDayString(weekday);

  var settings = await Settings.instance();
  return int.parse(settings.settings['duration.max.${weekDayString}s'] ?? '0');
}
