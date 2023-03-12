import '../db/timestamps.dart';

class Settings {
  static Settings? _singleton;
  static Map<String, String> _settings = {};

  Map<String, String> get settings => _settings;

  static Future<Settings> instance() async {
    if (_singleton == null) {
      _singleton = Settings();

      var database = await getTimestampDatabase();
      var query = 'SELECT key, value FROM Settings';
      var resultSet = await database.rawQuery(query);

      _settings = {
        for (var result in resultSet) result['key']: result['value']
      };
    }

    return _singleton!;
  }

  static Future<List> listAllSettings() async {
    var database = await getTimestampDatabase();

    var query = 'SELECT * FROM Settings';
    var values = [];
    return await database.rawQuery(query, values);
  }
}
