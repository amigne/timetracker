import 'package:flutter/material.dart';

import 'package:percent_indicator/percent_indicator.dart';

import '../db/timestamps.dart';

class TimerView extends StatefulWidget {
  const TimerView({Key? key}) : super(key: key);

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  bool _active = false;
  String _totalTime = '00:00';
  String _lastTimestamp = '';

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
          percent: 1.0,
          center: Column(
            mainAxisSize: MainAxisSize.min,
          children: [Text(
            _totalTime,
            style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.5),
          ),
          Text('Last: $_lastTimestamp')],
          ),
          progressColor: _active ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  tapMaker(context) {
    return () async {
      await addTimestamp()
          .then((_) { updateState(); })
          .catchError((error, stackTrace) {
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Existing timestamp'),
            content: const Text('There must be at least a one minute difference between two timestamps.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }, test: (e) => e is AlreadySameTimestampException,
      );
    };
  }

  void updateState() async {
    var timestampsNumber = await getTodayActiveTimestamps();
    var totalTime = await getTotalTime();
    var lastTimestamp = await getLastTimestamp();
    setState(()  {
      _active = timestampsNumber % 2 == 1;
      _totalTime = totalTime;
      _lastTimestamp = lastTimestamp;
    });
  }
}
