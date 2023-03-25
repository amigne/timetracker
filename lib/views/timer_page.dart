import 'dart:async';

import 'package:flutter/material.dart';

import 'package:percent_indicator/percent_indicator.dart';

import '../models/setting.dart';
import '../models/timestamp.dart';
import '../timestamps/timestamp_extension.dart';
import '../utils/datetime.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  String _totalTime = '00:00';
  String _lastTimestamp = '';
  double _percent = 0.0;
  Color _progressColor = Colors.grey;
  Color _backgroundColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: tapMaker(context),
        child: CircularPercentIndicator(
          radius: 100,
          lineWidth: 5.0,
          percent: _percent,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _totalTime,
                style: DefaultTextStyle.of(context)
                    .style
                    .apply(fontSizeFactor: 2.5),
              ),
              Text(_lastTimestamp)
            ],
          ),
          progressColor: _progressColor,
          backgroundColor: _backgroundColor,
        ),
      ),
    );
  }

  tapMaker(context) {
    return () async {
      await TimestampExtension.addTimestamp().then((_) {
        updateState();
      }).catchError(
        (error, stackTrace) {
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Existing timestamp'),
              content: const Text(
                  'There must be at least a one minute difference between two timestamps.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        test: (e) => e is AlreadySameTimestampException,
      );
    };
  }

  void updateState() async {
    if (!mounted) return;

    final timestampsNumber =
        await TimestampExtension.countTodayActiveTimestamps();
    final totalTime = await TimestampExtension.getTotalDuration();
    final lastTimestamp = await TimestampExtension.getLastTimestamp();
    final lastTimestampStr = lastTimestamp != null
        ? 'Last: ${await TimestampExtension.displayTime(lastTimestamp.utcTimestamp)}'
        : '';
    final expectedWorkDuration = await getExpectedWorkDuration();
    final maximumWorkDuration = await getMaximumWorkDuration();
    var ratio = totalTime.inMinutes / expectedWorkDuration;

    final active = timestampsNumber % 2 == 1;
    Color progressColor;
    Color backgroundColor;
    double percent;
    if (ratio <= 1.0) {
      percent = ratio;
      progressColor = active ? Colors.green.shade700 : Colors.green.shade300;
      backgroundColor = active ? Colors.blue.shade400 : Colors.grey.shade300;
    } else {
      ratio = (totalTime.inMinutes - expectedWorkDuration) /
          (maximumWorkDuration - expectedWorkDuration);
      if (maximumWorkDuration >= expectedWorkDuration && ratio <= 1.0) {
        percent = ratio;
        progressColor =
            active ? Colors.orange.shade700 : Colors.orange.shade300;
        backgroundColor =
            active ? Colors.green.shade700 : Colors.green.shade300;
      } else {
        percent = 1.0;
        progressColor = active ? Colors.red : Colors.red.shade200;
        backgroundColor = Colors.red;
      }
    }

    setState(() {
      _totalTime = displayDuration(totalTime);
      _lastTimestamp = lastTimestampStr;
      _percent = percent;
      _progressColor = progressColor;
      _backgroundColor = backgroundColor;
      var now = DateTime.now();
      Future.delayed(Duration(seconds: 60 - now.second), () {
        updateState();
      });
    });
  }

  // TODO: Move method to dedicated class
  Future<int> getExpectedWorkDuration() async {
    final weekDay = await TimestampExtension.getWeekDayString();

    return int.parse((await Setting.get('duration.$weekDay')) ?? '0');
  }

  // TODO: Move method to dedicated class
  Future<int> getMaximumWorkDuration() async {
    final weekDay = await TimestampExtension.getWeekDayString();

    return int.parse((await Setting.get('duration.max.$weekDay')) ?? '0');
  }
}
