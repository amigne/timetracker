import 'package:flutter/material.dart';

import 'time_tracker_home.dart';

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TimeTrackerHome(),
    );
  }
}
