import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

import '../db/timestamps.dart';
import './settings.dart';

void backupAndShareDB() async {
  final settings = await Settings.listAllSettings();
  final timestamps = await listAllTimestamps();

  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0"');
  builder.element('timetracker', nest: () {
    _buildSettings(builder, settings);
    _buildTimestamps(builder, timestamps);
  });

  final document = builder.buildDocument();

  var directory = (await getApplicationDocumentsDirectory()).path;

  File(join('$directory/timetracker.xml'))
    ..createSync(recursive: true)
    ..writeAsStringSync(document.toString());

  Share.shareXFiles([XFile('$directory/timetracker.xml')], text: 'XML backup for Time Tracker');
}

void _buildSettings(XmlBuilder builder, settings)  {
  builder.element('settings', nest: () {
    _buildSettingsItems(builder, settings);
  });
}

void _buildSettingsItems(XmlBuilder builder, settings) {
  for (var setting in settings) {
    builder.element('setting', nest: () {
      builder.attribute('id', setting['id'].toString());
      builder.element('key', nest: () {
        builder.text(setting['key']);
      });
      builder.element('value', nest: () {
        builder.text(setting['value']);
      });
    });
  }
}

void _buildTimestamps(XmlBuilder builder, timestamps)  {
  builder.element('timestamps', nest: () {
    _buildTimestampsItems(builder, timestamps);
  });
}

void _buildTimestampsItems(XmlBuilder builder, timestamps) {
  for (var timestamp in timestamps) {
    builder.element('timestamp', nest: () {
      builder.attribute('id', timestamp['id'].toString());
      builder.element('dateTime', nest: () {
        builder.text(timestamp['dateTime'].toString());
      });
      builder.element('origin', nest: () {
        builder.text(timestamp['origin'].toString());
      });
      builder.element('deleted', nest: () {
        builder.text(timestamp['deleted'] == 0 ? 'false' : 'true');
      });
    });
  }
}
