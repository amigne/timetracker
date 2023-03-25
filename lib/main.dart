import 'package:flutter/material.dart';

import 'package:timezone/data/latest.dart' as tz;

import 'views/time_tracker_app.dart';

Future<void> init() async {
  tz.initializeTimeZones();

  WidgetsFlutterBinding.ensureInitialized();
}

Future<void> main() async {
  await init();

  runApp(const TimeTrackerApp());
}
