// ignore_for_file: file_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:joke_calendar/DisplayEvent.dart';
import 'package:joke_calendar/shared.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  CalendarState createState() => CalendarState();
}

class CalendarState extends State<Calendar> {
  bool isLoaded = false;
  late List<Event> _selectedEvents;
  late List<Event> _currentMonthEvents;
  late DataHelper dataHelper;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  int _currentMonth = DateTime.now().month;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  void init() async {
    dataHelper = DataHelper.init();
    _currentMonthEvents = await _getEventsForMonth();
    setState(() {
      _selectedEvents = _getEventsForDay(_selectedDay!);
      isLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  refresh() async {
    _currentMonthEvents = await _getEventsForMonth();
    setState(() {
      _selectedEvents = _getEventsForDay(_selectedDay!);
      isLoaded = true;
    });
  }

  Future<List<Event>> _getEventsForMonth() async {
    return (await dataHelper.getAllEvents())
        .where((event) => event.day.month == _currentMonth)
        .toList();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _currentMonthEvents
        .where((event) => event.day.day == day.day)
        .toList();
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    List<DateTime> days = daysInRange(start, end);

    return [
      for (DateTime d in days) ..._getEventsForDay(d),
    ];
  }

  List<DateTime> daysInRange(DateTime first, DateTime last) {
    final dayCount = last.difference(first).inDays + 1;
    return List.generate(
      dayCount,
      (index) => DateTime.utc(first.year, first.month, first.day + index),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      setState(() {
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    _getEventsForMonth().then((events) => setState(() {
          _currentMonthEvents = events;
          if (start != null && end != null) {
            _selectedEvents = _getEventsForRange(start, end);
          } else if (start != null) {
            _selectedEvents = _getEventsForDay(start);
          } else if (end != null) {
            _selectedEvents = _getEventsForDay(end);
          }
        }));
  }

  openEventEditor([int? id]) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayEvent(
            id: id,
            time:
                "${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}",
          ),
        ));
    refresh(); // refresh values after returning to this screen
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded == false) {
      return const SafeArea(
          child: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ));
    }

    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
            onPressed: openEventEditor, child: const Icon(Icons.add)),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TableCalendar<Event>(
                onFormatChanged: (format) {},
                firstDay: DateTime(2021, 9, 21),
                lastDay: DateTime(2031, 9, 21),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(formatButtonShowsNext: false),
                rangeSelectionMode: _rangeSelectionMode,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: const CalendarStyle(
                  isTodayHighlighted: true,
                  markerDecoration: BoxDecoration(
                      color: Color.fromARGB(255, 17, 255, 0),
                      shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                      color: Color.fromRGBO(144, 202, 249, 1),
                      shape: BoxShape.circle),
                ),
                onDaySelected: _onDaySelected,
                onRangeSelected: _onRangeSelected,
                onPageChanged: (focusedDay) async {
                  _currentMonth = focusedDay.month;
                  _currentMonthEvents = await _getEventsForMonth();
                  _getEventsForMonth();
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
                child: ListView.separated(
              primary: false,
              shrinkWrap: true,
              itemCount: _selectedEvents.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    horizontalTitleGap: 0,
                    dense: true,
                    trailing: Text(
                        ("${formatTime(_selectedEvents[index].timeSpan["start"]!)} - ${formatTime(_selectedEvents[index].timeSpan["end"]!)}")),
                    leading: _selectedEvents[index].image != "null" &&
                            _selectedEvents[index].image != null
                        ? CircleAvatar(
                            backgroundImage:
                                FileImage(File(_selectedEvents[index].image!)),
                            radius: 60,
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.blue[200],
                            radius: 60,
                            child: const Icon(Icons.person),
                          ),
                    onTap: () {
                      openEventEditor(_selectedEvents[index].id);
                    },
                    title: Text(_selectedEvents[index].title));
              },
            ))
          ],
        ),
      ),
    );
  }
}
