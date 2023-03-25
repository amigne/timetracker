import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xml/xml.dart';

import '../models/setting.dart';
import '../models/timestamp.dart';

class DatabaseHelper {
  static const _databaseFileName = 'timetracker.db';
  static const _databaseVersion = 1;
  static const _onCreateModels = [Setting.onCreate, Timestamp.onCreate];
  static const _onBackupModels = [
    [Setting.query, Setting.onBackup],
    [Timestamp.queryBackup, Timestamp.onBackup]
  ];

  static Database? _database;

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final databaseDirectory = await databaseFactory.getDatabasesPath();
    final path = join(databaseDirectory, _databaseFileName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database database, int version) async {
    for (var onCreateModel in _onCreateModels) {
      await onCreateModel(database, version);
    }
  }

  static Future<XmlDocument> backup() async {
    final data = [for (var model in _onBackupModels) await model[0]()];

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('timetracker', nest: () {
      for (var i = 0; i < _onBackupModels.length; ++i) {
        _onBackupModels[i][1](builder, data[i]);
      }
    });

    return builder.buildDocument();
  }
}
