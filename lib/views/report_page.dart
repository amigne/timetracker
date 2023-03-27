import 'package:flutter/material.dart';

import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../reports/share_excel.dart';
import '../settings/setting_extension.dart';
import '../timestamps/datetime_extension.dart';
import '../utils/datetime.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime? _startMonth;
  DateTime? _endMonth;
  DateTime? _selectedMonth;
  String _selectedMonthStr = '';

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
        GestureDetector(
          onTap: changeMonthMaker(context),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_selectedMonthStr),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => shareExcel(_selectedMonthStr),
          child: const Text('Share Excel'),
        )
      ],
    );
  }

  void updateState() async {
    if (!mounted) return;

    final startMonth = _startMonth ?? (await SettingExtension.startDate()).toLocal();
    final endMonth = _endMonth ?? await DateTimeExtension.tzNow();
    final selectedMonth = _selectedMonth ?? await DateTimeExtension.tzNow();
    final selectedMonthStr = formatMonth(selectedMonth.year, selectedMonth.month);
    setState(() {
      _startMonth = startMonth;
      _endMonth = endMonth;
      _selectedMonth = selectedMonth;
      _selectedMonthStr = selectedMonthStr;
    });
  }

  changeMonthMaker(context) {
    return () async {
      print('changeMonthMaker');
      print(' - initialDate: $_selectedMonth');
      print(' - firstDate: $_startMonth');
      print(' - lastDate: $_endMonth');
      final DateTime? pickedMonth = await showMonthPicker(
        context: context,
        initialDate: _selectedMonth,
        firstDate: _startMonth,
        lastDate: _endMonth,
      );

      if (pickedMonth == null) return;

      _selectedMonth = pickedMonth;
      updateState();
    };
  }
}
