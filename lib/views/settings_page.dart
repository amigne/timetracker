import 'package:flutter/material.dart';

import '../db/timestamps.dart';
import '../reports/share_excel.dart';
import '../settings/backup.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /* bool _set = false;
  List<String> _dropdownList = [];
  String _dropdownValue = '';
   */

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

  /*
  void updateState() async {
    if (!mounted) return;

    if (!_set) {
      var dropdownList = await getListOfMonths();
      var dropdownValue = dropdownList[0];

      _set = true;
      setState(() {
        _dropdownList = dropdownList;
        _dropdownValue = dropdownValue;
      });
    }
  }
   */
}
