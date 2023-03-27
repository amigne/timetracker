import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../settings/backup.dart';

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

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Backup'),
        ElevatedButton(
          onPressed: backupAndShareDB,
          child: const Text('Backup & share DB'),
        ),
        ElevatedButton(
          onPressed: importDB,
          child: const Text('Import DB'),
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
}
