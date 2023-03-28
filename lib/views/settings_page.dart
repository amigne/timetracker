import 'dart:core';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timetracker/reports/share_excel.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/setting.dart';
import '../settings/backup.dart';
import '../settings/setting_extension.dart';
import '../utils/datetime.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  List<DropdownMenuItem> _timeZoneList = [];
  String _timeZone = '';
  DateTime? _startDate;
  String _startDateStr = '';
  List<TableRow> _workingDurationTableRows = [];
  BuildContext? _context;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    setState(() {
      _timeZoneList = [
        for (var tz in tz.timeZoneDatabase.locations.keys)
          DropdownMenuItem<String>(value: tz, child: Text(tz))
      ];
    });

    updateState();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return ListView(
      children: [
        ListTile(
          title: const Center(child: Text('Backup')),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: backupAndShareDB,
                child: const Text('Backup & share DB'),
              ),
              ElevatedButton(
                onPressed: importDB,
                child: const Text('Import DB'),
              ),
            ],
          ),
        ),
        ListTile(
          title: const Center(child: Text('Time zone')),
          subtitle: Center(child: _timeZoneDropdown()),
        ),
        ListTile(
          title: const Center(child: Text('Start date')),
          subtitle: GestureDetector(
            onTap: _changeDateMaker(context),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_startDateStr),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
        ListTile(
          title: const Center(child: Text('Working durations')),
          subtitle: Table(
            children: _workingDurationTableRows,
          ),
        ),
        _infoTile('App name', _packageInfo.appName),
        _infoTile('Package name', _packageInfo.packageName),
        _infoTile('App version', _packageInfo.version),
        _infoTile('Build number', _packageInfo.buildNumber),
        _infoTile('Build signature', _packageInfo.buildSignature),
        _infoTile(
          'Installer store',
          _packageInfo.installerStore ?? 'not available',
        ),
      ],
    );
  }

  Widget _infoTile(String title, String subtitle) {
    return ListTile(
      title: Center(child: Text(title)),
      subtitle: Center(child: Text(subtitle.isEmpty ? 'Not set' : subtitle)),
    );
  }

  Widget _timeZoneDropdown() {
    if (_timeZone == '') {
      return Container();
    }

    return DropdownButton(
      items: _timeZoneList,
      value: _timeZone,
      onChanged: _updateTimeZoneMaker(),
    );
  }

  void backupAndShareDB() async {
    await backup();
    await shareDB();
  }

  void importDB() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'xml',
      ],
    );
    if (result != null) {
      await restore(result.files.single.path!);
    }
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  void updateState() async {
    if (!mounted) return;

    final timeZone = (await Setting.get('general.timeZone')) ?? 'UTC';
    final startDate = tz.TZDateTime.from(
        await SettingExtension.startDate(), tz.getLocation(timeZone));
    final startDateStr =
        formatDate(startDate.year, startDate.month, startDate.day);

    final List<TableRow> workingDurationTableRows = [];

    workingDurationTableRows.add(TableRow(
      children: [
        Container(),
        Container(margin: const EdgeInsets.all(5.0), child: const Text('due')),
        Container(margin: const EdgeInsets.all(5.0), child: const Text('max')),
      ],
    ));

    const weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    for (var weekday in weekdays) {
      final due =
          int.parse((await Setting.get('duration.due.$weekday')) ?? '0');
      final max =
          int.parse((await Setting.get('duration.max.$weekday')) ?? '0');
      final dueStr = displayDuration(Duration(minutes: due));
      final maxStr = displayDuration(Duration(minutes: max));

      workingDurationTableRows.add(TableRow(
        children: [
          Container(
              margin: const EdgeInsets.all(5.0),
              child: Text(weekday.capitalize())),
          GestureDetector(
            onTap: _updateDailyDurationMaker(due, 'due', weekday),
            child: Container(
                margin: const EdgeInsets.all(5.0), child: Text(dueStr)),
          ),
          GestureDetector(
            onTap: _updateDailyDurationMaker(max, 'max', weekday),
            child: Container(
                margin: const EdgeInsets.all(5.0), child: Text(maxStr)),
          ),
        ],
      ));
    }

    setState(() {
      _timeZone = timeZone;
      _startDate = startDate;
      _startDateStr = startDateStr;
      _workingDurationTableRows = workingDurationTableRows;
    });
  }

  _updateDailyDurationMaker(int minutes, String typeDuration, String weekDay) {
    return () async {
      if (_context == null) return;

      final TimeOfDay? pickedDuration = await showTimePicker(
        context: _context!,
        helpText: 'Select $typeDuration duration for ${weekDay}s',
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (pickedDuration == null) return;

      final newDuration = pickedDuration.hour * 60 + pickedDuration.minute;

      if (typeDuration == 'max') {
        final due = int.parse(
            (await Setting.get('duration.due.$weekDay')) ?? '0');
        if (newDuration < due) {
          await showDialog(
              context: _context!,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Invalid max duration'),
                  content: Text(
                      'The maximum duration for a given day ($weekDay) '
                          'must be equal or higher than the due duration for that day.'),
                  actions: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme
                            .of(context)
                            .textTheme
                            .labelLarge,
                      ),
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                );
              }
          );
          return;
        }
      }
      if (typeDuration == 'due') {
        final max = int.parse((await Setting.get('duration.max.$weekDay')) ?? '0');
        if (newDuration > max) {
          await showDialog(
              context: _context!,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Invalid due duration'),
                  content: Text('The due duration for a given day ($weekDay) '
                      'must be smaller or equal to the max duration for that day.'),
                  actions: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      child: const Text('OK'),
                      onPressed: () { Navigator.of(context).pop(); },
                    )
                  ],
                );
              }
          );
          return;
        }
      }

      final durationResult = await Setting.query(key: 'duration.$typeDuration.$weekDay');
      final durationSetting = durationResult.isNotEmpty
          ? durationResult[0]
          : Setting(key: 'duration.$typeDuration.$weekDay', value: '');
      durationSetting.value = newDuration.toString();
      durationSetting.save();

      updateState();
    };
  }

  _updateTimeZoneMaker() {
    return (value) async {
      final timeZones = await Setting.query(key: 'general.timeZone');
      final timeZone = timeZones.isNotEmpty
          ? timeZones[0]
          : Setting(key: 'general.timeZone', value: value);
      timeZone.value = value;
      timeZone.save();
      updateState();
    };
  }

  _changeDateMaker(context) {
    return () async {
      // If initialization has not completed, let's return until values are set.
      if (_startDate == null) return;
      final tzApp = tz.getLocation(_timeZone);
      final firstDate = tz.TZDateTime(tzApp, 2000, 1, 1);
      final nowDate = tz.TZDateTime.now(tzApp);
      final lastDate = tz.TZDateTime(tzApp, nowDate.year + 1, 12, 31);

      final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _startDate!,
          firstDate: firstDate,
          lastDate: lastDate);

      if (pickedDate == null) return;

      final startDateResult =
          await Setting.query(key: 'general.startUtcTimestamp');
      final startDateSetting = startDateResult.isNotEmpty
          ? startDateResult[0]
          : Setting(key: 'general.startUtcTimestamp', value: '');
      startDateSetting.value =
          pickedDate.toUtc().millisecondsSinceEpoch.toString();
      startDateSetting.save();

      updateState();
    };
  }
}
