import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

enum TimestampsOrigin {
  inputClick,
  inputManual,
}

class Timestamp {
  static final Future<Database> _database = DatabaseHelper().database;
  static const _tableName = 'timestamps';
  static const _idColumnName = 'id';
  static const _utcTimestampColumnName = 'utcTimestamp';
  static const _originColumnName = 'origin';
  static const _deletedColumnName = 'deleted';

  int? _id;
  late final int _utcTimestamp;
  late final int _origin;
  late int _deleted;

  Timestamp({int? id, required int utcTimestamp, int? origin, int deleted = 0})
      : _id = id,
        _utcTimestamp = utcTimestamp,
        _origin = origin ?? TimestampsOrigin.inputClick.index,
        _deleted = deleted;

  int? get id => _id;

  int get utcTimestamp => _utcTimestamp;

  TimestampsOrigin get origin => TimestampsOrigin.values[_origin];

  bool get deleted => _deleted != 0;

  set deleted(bool deleted) => _deleted = deleted ? 1 : 0;

  @override
  String toString() {
    return DateTime.fromMillisecondsSinceEpoch(_utcTimestamp, isUtc: true)
        .toString();
  }

  Future<bool> save() async {
    if (_id == null) {
      return await _insert();
    }
    return await _update();
  }

  Future<bool> _insert() async {
    final database = await _database;

    try {
      _id = await database.insert(_tableName, _toMapForDB());
    } on DatabaseException {
      // TODO: handle error information for details about the false value
      return false;
    }

    return true;
  }

  Future<bool> _update() async {
    final database = await _database;

    try {
      database.update(
        _tableName,
        _toMapForDB(),
        where: '$_idColumnName = ?',
        whereArgs: [id],
      );
    } on DatabaseException {
      // TODO: handle error information for details about the false value
      return false;
    }

    return true;
  }

  Map<String, dynamic> _toMapForDB() => {
        _idColumnName: id,
        _utcTimestampColumnName: utcTimestamp,
        _originColumnName: _origin,
        _deletedColumnName: _deleted,
      };

  static Timestamp _fromMapToTimestamp(Map<String, Object?> map) => Timestamp(
        id: int.parse(map[_idColumnName] as String),
        utcTimestamp: int.parse(map[_utcTimestampColumnName] as String),
        origin: int.parse(map[_originColumnName] as String),
        deleted: int.parse(map[_deletedColumnName] as String),
      );

  static Future<List<Timestamp>> query({
    int? id,
    int? utcTimestamp,
    int? utcTimestampMin,
    int? utcTimestampMax,
    Object? origin,
    Object? deleted,
  }) async {
    if ((utcTimestamp != null) &&
        (utcTimestampMin != null || utcTimestampMax != null)) {
      throw ArgumentError(
          'utcTimestamp cannot be used with utcTimestampMin or utcTimestampMax');
    }

    final database = await _database;

    final result = <Timestamp>[];

    final values = [];
    final whereParts = <String>[];
    if (id != null) {
      whereParts.add('$_idColumnName = ?');
      values.add(id);
    }
    if (utcTimestamp != null) {
      whereParts.add('$_utcTimestampColumnName = ?');
      values.add(utcTimestamp);
    }
    if (utcTimestampMin != null) {
      whereParts.add('$_utcTimestampColumnName >= ?');
      values.add(utcTimestampMin);
    }
    if (utcTimestampMax != null) {
      whereParts.add('$_utcTimestampColumnName <= ?');
      values.add(utcTimestampMax);
    }
    if (origin is int || origin is TimestampsOrigin) {
      whereParts.add('$_originColumnName = ?');
      values.add(origin is int ? origin : (origin as TimestampsOrigin).index);
    } else if (origin != null) {
      throw ArgumentError(
          'origin, when specified, must either be an int or a TimestampsOrigin enumeration value.');
    }
    if (deleted is bool || deleted is int) {
      whereParts.add('$_deletedColumnName = ?');
      values.add(deleted is int ? deleted : ((deleted as bool) ? 1 : 0));
    } else if (deleted != null) {
      throw ArgumentError(
          'deleted, when specified, must either be an int or a bool value.');
    }

    final where =
        whereParts.isNotEmpty ? ' WHERE ${whereParts.join(' AND ')}' : '';

    var query = 'SELECT * FROM $_tableName$where';
    final records = await database.rawQuery(query, values.toList());

    for (var record in records) {
      result.add(_fromMapToTimestamp(record));
    }

    return result;
  }

  static Future<void> onCreate(Database database, int version) async {
    database.execute('DROP TABLE IF EXISTS $_tableName');
    database.execute('''CREATE TABLE $_tableName (
        $_idColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_utcTimestampColumnName INTEGER NOT NULL,
        $_originColumnName INTEGER NOT NULL,
        $_deletedColumnName INTEGER NOT NULL
    )''');
  }

  static Future<void> onUpdate(
      Database database, int oldVersion, int newVersion) async {}
}
