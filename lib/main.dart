import 'package:flutter/material.dart';
import 'package:joke_calendar/Calendar.dart';
// import 'package:joke_calendar/notificationservice.dart';
import 'package:joke_calendar/notificationservice.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService().initNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomek\'s Calendar',
      theme: ThemeData(),
      home: const Calendar(),
      debugShowCheckedModeBanner: false,
    );
  }
}
