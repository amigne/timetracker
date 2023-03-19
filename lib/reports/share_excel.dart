import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/timestamps.dart';

Map<int, String> months = {
  DateTime.january: 'january',
  DateTime.february: 'february',
  DateTime.march: 'march',
  DateTime.april: 'april',
  DateTime.may: 'may',
  DateTime.june: 'june',
  DateTime.july: 'july',
  DateTime.august: 'august',
  DateTime.september: 'september',
  DateTime.october: 'october',
  DateTime.november: 'november',
  DateTime.december: 'december',
};

Map<int, String> weekDays = {
  DateTime.monday: 'monday',
  DateTime.tuesday: 'tuesday',
  DateTime.wednesday: 'wednesday',
  DateTime.thursday: 'thursday',
  DateTime.friday: 'friday',
  DateTime.saturday: 'saturday',
  DateTime.sunday: 'sunday',
};

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

String _monthName(month) {
  var parts = month.split('-');
  var monthInt = int.parse(parts[1]);

  return (months[monthInt] ?? 'unknown').capitalize();
}

String _year(month) => month.split('-')[0];

String _weekDayName(int weekday, {int truncate = 0}) {
  var weekDay = (weekDays[weekday] ?? 'unknown').capitalize();
  if (truncate > 0) {
    weekDay = weekDay.substring(0, truncate);
  }
  return weekDay;
}

void shareExcel(String yearMonth) async {
  final excel = Excel.createExcel();
  excel.rename(excel.getDefaultSheet()!, yearMonth);
  excel.setDefaultSheet(yearMonth);
  Sheet sheet = excel[yearMonth];

  // Title
  sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'),
      customValue: 'Timestamps - ${_monthName(yearMonth)} ${_year(yearMonth)}');
  sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
    fontSize: 18,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
  );

  sheet.setColWidth(1, 60.0);

  final borderMedium = Border(borderStyle: BorderStyle.Medium);
  final borderThin = Border(borderStyle: BorderStyle.Thin);
  final borderHair = Border(borderStyle: BorderStyle.Hair);

  // Table header
  final headerLeftCellStyle = CellStyle(
    bold: true,
    bottomBorder: borderMedium,
    rightBorder: borderThin,
  );
  final headerCenterCellStyle = CellStyle(
    bold: true,
    bottomBorder: borderMedium,
    rightBorder: borderThin,
    leftBorder: borderThin,
  );
  final headerRightCellStyle = CellStyle(
    bold: true,
    bottomBorder: borderMedium,
    leftBorder: borderThin,
  );
  sheet.cell(CellIndex.indexByString('A3'))
    ..value = 'Date'
    ..cellStyle = headerLeftCellStyle;
  sheet.cell(CellIndex.indexByString('B3'))
    ..value = 'Timestamps'
    ..cellStyle = headerCenterCellStyle;
  sheet.cell(CellIndex.indexByString('C3'))
    ..value = 'Total'
    ..cellStyle = headerCenterCellStyle;
  sheet.cell(CellIndex.indexByString('D3'))
    ..value = 'Target'
    ..cellStyle = headerCenterCellStyle;
  sheet.cell(CellIndex.indexByString('E3'))
    ..value = 'Difference'
    ..cellStyle = headerRightCellStyle;

  final year = int.parse(yearMonth.split('-')[0]);
  final month = int.parse(yearMonth.split('-')[1]);

  final dateCellStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Right,
    verticalAlign: VerticalAlign.Top,
    rightBorder: borderThin,
    bottomBorder: borderHair,
  );
  final timestampsCellStyle = CellStyle(
    textWrapping: TextWrapping.WrapText,
    verticalAlign: VerticalAlign.Top,
    rightBorder: borderThin,
    leftBorder: borderThin,
    bottomBorder: borderHair,
  );
  final totalCellStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Right,
    verticalAlign: VerticalAlign.Top,
    rightBorder: borderThin,
    leftBorder: borderThin,
    bottomBorder: borderHair,
  );
  final targetCellStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Right,
    verticalAlign: VerticalAlign.Top,
    rightBorder: borderThin,
    leftBorder: borderThin,
    bottomBorder: borderHair,
  );
  final differenceCellStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Right,
    verticalAlign: VerticalAlign.Top,
    leftBorder: borderThin,
    bottomBorder: borderHair,
  );

  // Generate the timestamps table
  var line = 4;
  for (var dateTime = DateTime(year, month, 1);
      dateTime.month == month;
      dateTime = dateTime.add(const Duration(days: 1))) {
    final day = dateTime.day;
    final weekday = dateTime.weekday;

    // List of timestamps in milliseconds
    List<int> listTimestampsInMilliseconds =
        (await listTimestampsSingleDay(year, month, day))
            .map((timestamp) => timestamp['dateTime'] as int)
            .toList();
    listTimestampsInMilliseconds.sort((a, b) => a.compareTo(b));
    final numberOfTimestamps = listTimestampsInMilliseconds.length;

    // Date column
    sheet.cell(CellIndex.indexByString('A$line'))
      ..value =
          '${_weekDayName(weekday, truncate: 2)} ${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}'
      ..cellStyle = dateCellStyle;

    // Timestamps column
    List<String> listTimestamps = [];
    for (final millisecondsSinceEpoch in listTimestampsInMilliseconds) {
      listTimestamps.add(await displayTime(millisecondsSinceEpoch));
    }

    sheet.cell(CellIndex.indexByString('B$line'))
      ..value = listTimestamps.join(' ')
      ..cellStyle = timestampsCellStyle;

    // Total column
    var totalDuration = Duration.zero;
    if (numberOfTimestamps > 0 && numberOfTimestamps % 2 == 0) {
      int totalTime = 0;
      for (int i = 0; i < numberOfTimestamps; i += 2) {
        totalTime += (listTimestampsInMilliseconds[i + 1] -
            listTimestampsInMilliseconds[i]);
      }
      totalDuration = Duration(milliseconds: totalTime);
    }
    sheet.cell(CellIndex.indexByString('C$line'))
      ..value = displayDuration(totalDuration)
      ..cellStyle = totalCellStyle;

    // Target column
    final target = await getStandardWorkDurationForDay(weekday);
    final targetDuration = Duration(minutes: target);
    sheet.cell(CellIndex.indexByString('D$line'))
      ..value = displayDuration(targetDuration)
      ..cellStyle = targetCellStyle;

    // Difference column
    final differenceDuration = totalDuration - targetDuration;
    sheet.cell(CellIndex.indexByString('E$line'))
      ..value = displayDuration(differenceDuration)
      ..cellStyle = differenceCellStyle;

    line++;
  }

  final fileBytes = excel.save();
  final directory = (await getApplicationDocumentsDirectory()).path;

  File(join('$directory/$yearMonth.xlsx'))
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes!);

  Share.shareXFiles([XFile('$directory/$yearMonth.xlsx')],
      text: 'Monthly report for $yearMonth');
}
