import 'package:flutter/material.dart';

import 'package:timezone/data/latest.dart' as tz;

import 'settings/settings.dart';
import 'views/time_tracker_app.dart';

Future<void> init() async {
  // TODO: Determine if this is really necessary to preload this here...
  await Settings.instance();

  tz.initializeTimeZones();
}

Future<void> main() async {
  await init();

  runApp(const TimeTrackerApp());
}
