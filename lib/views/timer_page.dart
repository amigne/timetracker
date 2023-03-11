import 'dart:async';

import 'package:flutter/material.dart';

import 'package:percent_indicator/percent_indicator.dart';
import 'package:timetracker/db/timestamp.dart';

import '../db/timestamps.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  bool _active = false;
  String _totalTime = '00:00';
  String _lastTimestamp = '';

  // late Timer _timer;

  @override
  void initState() {
    super.initState();
    updateState();
    // _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => updateState());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: tapMaker(context),
        child: CircularPercentIndicator(
          radius: 100,
          lineWidth: 5.0,
          percent: 1.0,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _totalTime,
                style: DefaultTextStyle.of(context)
                    .style
                    .apply(fontSizeFactor: 2.5),
              ),
              Text('Last: $_lastTimestamp')
            ],
          ),
          progressColor: _active ? Colors.blue : Colors.grey,
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
    var timestampsNumber = await countTodayActiveTimestamps();
    var totalTime = await getTotalDuration();
    var lastTimestamp = await displayTime(await getLastTimestamp());

    setState(() {
      _active = timestampsNumber % 2 == 1;
      _totalTime = displayDuration(totalTime);
      _lastTimestamp = lastTimestamp;
      var now = DateTime.now();
      Future.delayed(Duration(seconds: 60 - now.second), () {
        updateState();
      });
    });
  }
}
