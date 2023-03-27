import 'package:sqflite/sqflite.dart';
import 'package:xml/xml.dart';

import '../db/database_helper.dart';

class Setting {
  static final Future<Database> _database = DatabaseHelper().database;
  static const _tableName = 'settings';
  static const _idColumnName = 'id';
  static const _keyColumnName = 'key';
  static const _valueColumnName = 'value';

  int? _id;
  late final String _key;
  late String value;

  Setting({id, required key, required this.value})
      : _id = id,
        _key = key;

  int? get id => _id;

  String get key => _key;

  @override
  String toString() => '$key: $value';

  Future<bool> save({bool forceInsert = false}) async {
    if (_id == null || forceInsert) {
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
        _keyColumnName: key,
        _valueColumnName: value,
      };

  static Setting _fromMapToSetting(Map<String, Object?> map) => Setting(
        id: map[_idColumnName],
        key: '${map[_keyColumnName]}',
        value: '${map[_valueColumnName]}',
      );

  static Future<String?> get(String key) async {
    final result = await query(key: key);

    return (result.length == 1) ? result[0].value : null;
  }

  static Future<List<Setting>> query(
      {int? id,
      String? key,
      String? value,
      bool strictKey = true,
      bool strictValue = true}) async {
    final database = await _database;

    final result = <Setting>[];

    final values = [];
    final whereParts = <String>[];
    if (id != null) {
      whereParts.add('$_idColumnName = ?');
      values.add(id);
    }
    if (key != null) {
      whereParts.add('$_keyColumnName ${strictKey ? '=' : 'LIKE'} ?');
      values.add(key);
    }
    if (value != null) {
      whereParts.add('$_valueColumnName ${strictKey ? '=' : 'LIKE'} ?');
      values.add(value);
    }

    final where =
        whereParts.isNotEmpty ? ' WHERE ${whereParts.join(' AND ')}' : '';

    var query = 'SELECT * FROM $_tableName$where';
    final records = await database.rawQuery(query, values.toList());

    for (var record in records) {
      result.add(_fromMapToSetting(record));
    }

    return result;
  }

  static Future<void> onCreate(Database database, int version,
      {bool populate = true}) async {
    database.execute('DROP TABLE IF EXISTS $_tableName');
    database.execute('''CREATE TABLE $_tableName (
        $_idColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_keyColumnName STRING NOT NULL,
        $_valueColumnName STRING NOT NULL,
        UNIQUE($_keyColumnName)
    )''');

    if (populate) {
      final now = DateTime.now();
      final todayTimestamp =
          DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch;
      Setting(key: 'general.startUtcTimestamp', value: '$todayTimestamp')
          .save();
      Setting(key: 'general.timeZone', value: 'Europe/Zurich').save();
      Setting(key: 'duration.due.monday', value: '492').save();
      Setting(key: 'duration.due.tuesday', value: '492').save();
      Setting(key: 'duration.due.wednesday', value: '492').save();
      Setting(key: 'duration.due.thursday', value: '492').save();
      Setting(key: 'duration.due.friday', value: '492').save();
      Setting(key: 'duration.due.saturday', value: '0').save();
      Setting(key: 'duration.due.sunday', value: '0').save();
      Setting(key: 'duration.max.monday', value: '660').save();
      Setting(key: 'duration.max.tuesday', value: '660').save();
      Setting(key: 'duration.max.wednesday', value: '660').save();
      Setting(key: 'duration.max.thursday', value: '660').save();
      Setting(key: 'duration.max.friday', value: '660').save();
      Setting(key: 'duration.max.saturday', value: '0').save();
      Setting(key: 'duration.max.sunday', value: '0').save();
    }
  }

  static Future<void> onUpdate(
      Database database, int oldVersion, int newVersion) async {}

  static void onBackup(XmlBuilder builder, settings) {
    builder.element('settings', nest: () {
      _buildBackupItems(builder, settings);
    });
  }

  static void _buildBackupItems(XmlBuilder builder, List<Setting> settings) {
    for (var setting in settings) {
      builder.element('setting', nest: () {
        builder.attribute('id', setting.id.toString());
        builder.element('key', nest: () {
          builder.text(setting.key);
        });
        builder.element('value', nest: () {
          builder.text(setting.value);
        });
      });
    }
  }

  static Future<void> onRestore(XmlElement xmlElement) async {
    final database = await _database;

    await onCreate(database, -1, populate: false);
    final xmlSettings = xmlElement.findAllElements('setting');
    for (var xmlSetting in xmlSettings) {
      final String? idAttribute = xmlSetting.getAttribute('id');
      final keyElement = xmlSetting.getElement('key');
      final valueElement = xmlSetting.getElement('value');

      if (idAttribute == null || keyElement == null || valueElement == null) {
        throw InvalidDatabaseBackupFile();
      }

      final int id = int.parse(idAttribute);
      final key = keyElement.text;
      final value = valueElement.text;

      final setting = Setting(id: id, key: key, value: value);
      await setting.save(forceInsert: true);
    }
  }
}
