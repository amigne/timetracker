import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    final startDate = tz.TZDateTime.from(await SettingExtension.startDate(), tz.getLocation(timeZone));
    final startDateStr = formatDate(startDate.year, startDate.month, startDate.day);

    setState(() {
      _timeZone = timeZone;
      _startDate = startDate;
      _startDateStr = startDateStr;
    });
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

      final startDateResult = await Setting.query(key: 'general.startUtcTimestamp');
      final startDateSetting = startDateResult.isNotEmpty
          ? startDateResult[0]
          : Setting(key: 'general.startUtcTimestamp', value: '');
      startDateSetting.value = pickedDate.toUtc().millisecondsSinceEpoch.toString();
      startDateSetting.save();

      updateState();
    };
  }
}
