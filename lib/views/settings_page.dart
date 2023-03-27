import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../settings/backup.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
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
      ],
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
}
