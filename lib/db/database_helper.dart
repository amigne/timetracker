import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/setting.dart';
import '../models/timestamp.dart';

class DatabaseHelper {
  static const _databaseFileName = 'timetracker.db';
  static const _databaseVersion = 1;
  static const _onCreateModels = [Setting.onCreate, Timestamp.onCreate];

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
}
