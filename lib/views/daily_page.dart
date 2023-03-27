import 'package:flutter/material.dart';

import '../models/timestamp.dart';
import '../settings/setting_extension.dart';
import '../timestamps/datetime_comparison.dart';
import '../timestamps/datetime_extension.dart';
import '../timestamps/timestamp_extension.dart';
import '../utils/datetime.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({Key? key}) : super(key: key);

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _selectedDate;
  String _selectedDateStr = '';
  List<TableRow> _tableRows = [];

  @override
  void initState() {
    super.initState();
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: changeDateMaker(context),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_selectedDateStr),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: addManualTimestampMaker(context),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        Table(
          children: _tableRows,
        ),
      ],
    );
  }

  changeDateMaker(context) {
    return () async {
      // If initialization has not completed, let's return until values are set.
      if (_selectedDate == null || _startDate == null || _endDate == null)
        return;

      final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate!,
          firstDate: _startDate!,
          lastDate: _endDate!);

      if (pickedDate == null) return;

      _selectedDate = pickedDate;
      updateState();
    };
  }

  addManualTimestampMaker(context) {
    return () async {
      final TimeOfDay? pickedTime = await showTimePicker(
          context: context, initialTime: const TimeOfDay(hour: 0, minute: 0));

      if (pickedTime == null) return;

      final year = _selectedDate!.year;
      final month = _selectedDate!.month;
      final day = _selectedDate!.day;
      final hours = pickedTime.hour;
      final minutes = pickedTime.minute;

      final dateTime = DateTime(year, month, day, hours, minutes);
      if (dateTime <= DateTime.now()) {
        await TimestampExtension.addTimestamp(
            timestamp: dateTime.millisecondsSinceEpoch,
            origin: TimestampsOrigin.inputManual);
      }
      updateState();
    };
  }

  void updateState() async {
    if (!mounted) return;

    final startDate = _startDate ?? await SettingExtension.startDate();
    final endDate = _endDate ?? await DateTimeExtension.tzNow();
    final selectedDate = _selectedDate ?? await DateTimeExtension.tzNow();
    final selectedDateStr =
        formatDate(selectedDate.year, selectedDate.month, selectedDate.day);

    final timestamps = (await TimestampExtension.listTimestampsSingleDay(
            selectedDate.year, selectedDate.month, selectedDate.day,
            includeDeleted: true))
        .toList();
    timestamps.sort((a, b) => a.utcTimestamp.compareTo(b.utcTimestamp));

    final List<TableRow> tableRows = [];
    var count = 0;
    for (var timestamp in timestamps) {
      var style = const TextStyle();
      var icon =
          count % 2 == 0 ? const Icon(Icons.input) : const Icon(Icons.output);
      var trashIcon = GestureDetector(
        onTap: deleteMaker(timestamp),
        child: const Icon(Icons.delete, color: Colors.red),
      );

      if (timestamp.deleted) {
        style = const TextStyle(decoration: TextDecoration.lineThrough);
        icon = const Icon(Icons.block);
        trashIcon = GestureDetector(
          onTap: undeleteMaker(timestamp),
          child: const Icon(Icons.delete_outlined, color: Colors.green),
        );
      }

      count += !timestamp.deleted ? 1 : 0;

      tableRows.add(TableRow(
        children: [
          icon,
          Text(await displayTime(timestamp.utcTimestamp), style: style),
          Text(getOriginAbbrev(timestamp.origin)),
          trashIcon,
        ],
      ));
    }

    setState(() {
      _startDate = startDate;
      _endDate = endDate;
      _selectedDate = selectedDate;
      _selectedDateStr = selectedDateStr;
      _tableRows = tableRows;
    });
  }

  deleteMaker(Timestamp timestamp) {
    return () async {
      timestamp.deleted = true;
      await timestamp.save();
      updateState();
    };
  }

  undeleteMaker(Timestamp timestamp) {
    return () async {
      timestamp.deleted = false;
      await timestamp.save();
      updateState();
    };
  }

  getOriginAbbrev(TimestampsOrigin origin) {
    switch (origin) {
      case TimestampsOrigin.inputClick:
        return 'A';
      case TimestampsOrigin.inputManual:
        return 'M';
      default:
        return '?';
    }
  }
}
