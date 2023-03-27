import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

import '../db/database_helper.dart';

Future<String> backupFilePath() async {
  final directory = (await getApplicationDocumentsDirectory()).path;
  return '$directory/timetracker_backup.xml';
}

Future<void> backup() async {
  final xmlDocument = await DatabaseHelper.backup();
  File(await backupFilePath())
    ..createSync(recursive: true)
    ..writeAsStringSync(xmlDocument.toString());
}

Future<void> shareDB() async {
  Share.shareXFiles([XFile(await backupFilePath())],
      text: 'XML backup for Time Tracker');
}

Future<void> restore(String filePath) async {
  final file = File(filePath);
  final xmlDocument = XmlDocument.parse(file.readAsStringSync());
  await DatabaseHelper.restore(xmlDocument);
}
