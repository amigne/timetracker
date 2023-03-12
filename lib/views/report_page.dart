import 'package:flutter/material.dart';

import '../db/timestamps.dart';
import '../reports/share_excel.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _set = false;
  List<String> _dropdownList = [];
  String _dropdownValue = '';

  @override
  void initState() {
    super.initState();
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Period'),
        DropdownButton<String>(
          value: _dropdownValue,
          items: _dropdownList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? value) {
            // This is called when the user selects an item.
            setState(() {
              _dropdownValue = value!;
            });
          },
        ),
        ElevatedButton(
          onPressed: () => shareExcel(_dropdownValue),
          child: const Text('Share Excel'),
        )
      ],
    );
  }

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
}
