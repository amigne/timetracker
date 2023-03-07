import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../db/timestamps.dart';
import 'timer.dart';

class TimeTrackerHome extends StatefulWidget {
  const TimeTrackerHome({Key? key}) : super(key: key);

  @override
  State<TimeTrackerHome> createState() => _TimeTrackerHomeState();
}

class _TimeTrackerHomeState extends State<TimeTrackerHome> {
  late PageController _pageController;
  int _page = 0;
  late dynamic _database;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
            child: Text('Time Tracker')
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: <Widget>[TimerView(), Placeholder(), Placeholder(),],
        onPageChanged: _onPageChanged,
      ),
      bottomNavigationBar: BottomNavigationBar(
        //backgroundColor: Theme.of(context).primaryColor,
        //selectedItemColor: Theme.of(context).colorScheme.secondary,
        //unselectedItemColor: Colors.grey[500],
        elevation: 20,
        type: BottomNavigationBarType.fixed,
        items: bottomNavigationBarItems,
        onTap: _navigationTapped,
        currentIndex: _page,
      ),


    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _database = getTimestampDatabase();
  }




  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void _navigationTapped(int page) {
    _pageController.jumpToPage(page);
  }

  void _onPageChanged(int page) => setState(() => _page = page);


  static const bottomNavigationBarItems =
  <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.timer),
      label: 'Timer',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.text_snippet),
      label: 'Today',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month),
      label: 'Reports',
    ),
  ];

}
