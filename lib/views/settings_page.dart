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
    // updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Backup'),
        ElevatedButton(
          onPressed: () => backupAndShareDB(),
          child: const Text('Backup & share DB'),
        )
      ],
    );
  }
}
