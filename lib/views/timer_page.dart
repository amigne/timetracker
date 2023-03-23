import 'dart:async';

import 'package:flutter/material.dart';

import 'package:percent_indicator/percent_indicator.dart';
import 'package:timetracker/db/timestamp.dart';

import '../db/timestamps.dart';
import '../settings/settings.dart';

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
      var timestamp = Timestamp(DateTime.now());
      await addTimestamp(timestamp: timestamp).then((_) {
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

    final timestampsNumber = await countTodayActiveTimestamps();
    final totalTime = await getTotalDuration();
    final lastTimestamp = await getLastTimestamp();
    final lastTimestampStr = lastTimestamp >= 0 ? 'Last: ${await displayTime(lastTimestamp)}' : '';
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
    var weekDay = await getWeekDayString();

    var settings = await Settings.instance();
    return int.parse(settings.settings['duration.${weekDay}s'] ?? '0');
  }

  // TODO: Move method to dedicated class
  Future<int> getMaximumWorkDuration() async {
    var weekDay = await getWeekDayString();

    var settings = await Settings.instance();
    return int.parse(settings.settings['duration.max.${weekDay}s'] ?? '0');
  }
}
