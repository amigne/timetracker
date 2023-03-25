import 'package:flutter/material.dart';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

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
  String _selectedTimeStr = '';

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
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Select the date'),
          content: SizedBox(
            height: 350,
            width: 350,
            child: Card(
              child: SfDateRangePicker(
                onSelectionChanged: dateChanged,
                selectionMode: DateRangePickerSelectionMode.single,
                initialSelectedDate: _selectedDate,
                minDate: _startDate,
                maxDate: _endDate,
              ),
            ),
          ),
          actions: const <Widget>[],
        ),
      );
    };
  }

  addManualTimestampMaker(context) {
    _selectedTimeStr = '';
    return () async {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Add a new timestamp'),
          content: SizedBox(
            height: 350,
            width: 350,
            child: Card(
              child: DateTimePicker(
                type: DateTimePickerType.time,
                use24HourFormat: true,
                initialValue: '00:00',
                timeLabelText: 'Time',
                onChanged: (val) => _selectedTimeStr = val,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: addNewTimestampMaker(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    };
  }

  addNewTimestampMaker(context) {
    return () async {
      final selectedTimeStr = _selectedTimeStr;
      final timeParts = selectedTimeStr.split(':');
      final year = _selectedDate!.year;
      final month = _selectedDate!.month;
      final day = _selectedDate!.day;
      final hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);

      final dateTime = DateTime(year, month, day, hours, minutes);

      if (dateTime <= DateTime.now()) {
        await TimestampExtension.addTimestamp(
            timestamp: dateTime.millisecondsSinceEpoch,
            origin: TimestampsOrigin.inputManual);
      }

      _selectedTimeStr = '';
      Navigator.pop(context);
      updateState();
    };
  }

  void dateChanged(DateRangePickerSelectionChangedArgs args) {
    Navigator.pop(context);
    _selectedDate = args.value;
    updateState();
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
      /*final timestamp = Timestamp(ts['dateTime'],
          id: ts['id'], origin: ts['origin'], deleted: ts['deleted'] != 0);*/

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
