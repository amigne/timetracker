import 'dart:io';
import 'dart:core';

import 'package:sqflite/utils/utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Timestamp {
  final int id;
  final String date;
  final String time;
  final int inputType;
  final bool deleted;

  static const inputTypeClick = 0;
  static const inputTypeManual = 1;

  Timestamp(
      {required this.id,
      required this.date,
      required this.time,
      this.inputType = inputTypeClick,
      this.deleted = false});

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

dynamic timestampDatabase;

dynamic getTimestampDatabase() async {
  return timestampDatabase ?? await openTimestampDatabase();
}

dynamic openTimestampDatabase({String filename = 'timestamps.db'}) async {
  if (timestampDatabase == null) {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }
    databaseFactory = databaseFactoryFfi;

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
  _createTableSettingsV1(batch);
  await batch.commit();
}

void _createTableTimestampV1(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS Timestamps');
  batch.execute('CREATE TABLE Timestamps ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'date TEXT, '
      'time TEXT, '
      'inputType INTEGER, '
      'deleted INTEGER'
      ')');
}

void _createTableSettingsV1(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS Settings');
  batch.execute('CREATE TABLE Settings ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'key TEXT, '
      'value TEXT'
      ')');
}

class AlreadySameTimestampException implements Exception {}

Future<void> addTimestamp(
    {String? date, String? time, int input = Timestamp.inputTypeClick}) async {
  DateTime now = DateTime.now();

  date ??= _formatDate(now.year, now.month, now.day);
  time ??= _formatTime(now.hour, now.minute);

  var database = await getTimestampDatabase();

  // Ensure there is now already a similar timestamp
  var result = await database.rawQuery(
      'SELECT time FROM Timestamps WHERE date=? AND time=? AND deleted=? ORDER BY time DESC', [date, time, 0]);
  if (result.length > 0) {
    throw AlreadySameTimestampException();
  }

  await database.insert('Timestamps',
      {'date': date, 'time': time, 'inputType': input, 'deleted': 0});
}

Future<int> getTodayActiveTimestamps() async {
  DateTime now = DateTime.now();
  var date = _formatDate(now.year, now.month, now.day);

  var database = await getTimestampDatabase();
  return firstIntValue(await database.rawQuery(
      'SELECT COUNT(*) FROM Timestamps WHERE date=? AND deleted=?',
      [date, 0]))!;
}

String _formatDate(int year, int month, int day) =>
    '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
String _formatTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

Future<String> getLastTimestamp() async {
  DateTime now = DateTime.now();
  var date = _formatDate(now.year, now.month, now.day);

  var database = await getTimestampDatabase();
  var result = await database.rawQuery(
      'SELECT time FROM Timestamps WHERE date=? AND deleted=? ORDER BY time DESC', [date, 0]);

  return result.length > 0 ? result[0]['time'] : '';
}

Future<String> getTotalTime([int? year, int? month, int? day]) async {
  DateTime now = DateTime.now();
  year = year ?? now.year;
  month = month ?? now.month;
  day =  day ?? now.day;
  var date = _formatDate(year!, month!, day!);

  var database = await getTimestampDatabase();
  var result = await database.rawQuery(
      'SELECT time FROM Timestamps WHERE date=? AND deleted=? ORDER BY time DESC', [date, 0]);
  var count = result.length;
  if (count <= 0) {
    return '0:00';
  }

  var times = result.map((dict) => dict['time']).toList();
  if (count % 2 == 1) {
    // Add current time to have an even number of records
    var time = _formatTime(now.hour, now.minute);
    times.insert(0, time);
  }

  var totalTime = 0.0;
  for (int i = 0; i < count; i += 2) {
    var time1 = getTimeStringToDouble(times[i]);
    var time2 = getTimeStringToDouble(times[i+1]);
    totalTime += (time1 - time2);
  }

  return getTimeDoubleToString(totalTime);
}

double getTimeStringToDouble(String time) {
  var splitted = time.split(':');
  var hour = int.parse(splitted[0]);
  var minutes = int.parse(splitted[1]);

  return hour + (minutes / 60);
}

String getTimeDoubleToString(double time) {
  var hour = time.truncate();
  var minutes = (time - hour) * 60;

  return _formatTime(hour, minutes.round());
}
