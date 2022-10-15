import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Event {
  late int? id;
  String title = "";
  bool isNew = false;
  DateTime day = DateTime.now();
  Map<String, double> timeSpan = {
    "start": 8.00,
    "end": 9.00,
  };
  String? image;

  Event() {
    isNew = true;
    id = Random().nextInt(10000);
  }

  List get value {
    return [title, day, timeSpan, image];
  }

  Event.fromSQLQuery(Map<String, dynamic> query) {
    id = query["id"];
    title = query["title"];
    day = DateTime.parse(query["day"]);
    timeSpan = {
      "start": double.parse(query["timeSpan"].split("-")[0]),
      "end": double.parse(query["timeSpan"].split("-")[1]),
    };
    image = query["image"];
  }
}

class DataHelper {
  Database? _db;

  DataHelper.init() {
    getDatabasesPath()
        .then((path) => openDatabase(join(path, "data.sql")).then((db) async {
              _db = db;

              _db!.rawQuery("""
                CREATE TABLE IF NOT EXISTS Events (
                  id INTEGER PRIMARY KEY NOT NULL,
                  title TEXT NOT NULL,
                  day TEXT NOT NULL,
                  timeSpan TEXT NOT NULL,
                  image TEXT
                )
              """);
            }));
  }

  Future get(key) async {
    if (_db == null) {
      await Future.delayed(const Duration(milliseconds: 10));
      return get(key);
    }
    return await _db!.rawQuery("sql");
  }

  ensureDb() async {
    if (_db == null) {
      await Future.delayed(const Duration(milliseconds: 10));
      return ensureDb();
    }
    return;
  }

  saveEvent(Event event) async {
    await ensureDb();

    if (!event.isNew) {
      return _db!.rawUpdate("""
        UPDATE Events
        SET
          title = '${event.title}',
          day = '${event.day}',
          timeSpan = '${event.timeSpan["start"]}-${event.timeSpan["end"]}',
          image = '${event.image}'
      WHERE id = ${event.id}""");
    } else {
      return _db!.rawInsert("""
        INSERT INTO Events (id, title, day, timeSpan, image)
        VALUES('${event.id}', '${event.title}', '${event.day}', '${event.timeSpan["start"]}-${event.timeSpan["end"]}', '${event.image}')
      """);
    }
  }

  Future<Event> getEventById(int id) async {
    await ensureDb();

    return Event.fromSQLQuery(
        (await _db!.rawQuery("SELECT * FROM Events WHERE id = $id")).single);
  }

  Future<List<Event>> getAllEvents() async {
    await ensureDb();

    return [
      for (Map<String, Object?> eventData
          in await _db!.rawQuery("SELECT * FROM Events"))
        Event.fromSQLQuery(eventData)
    ];
  }

  deleteEvent(int id) async {
    await ensureDb();

    return _db!.rawDelete("DELETE FROM Events WHERE id = $id");
  }
}

String formatTime(double time) {
  int hour = time.truncate();
  int minutes = (100 * (time - time.truncate())).round();
  return "${(hour < 10 ? "0" : "")}$hour:${(minutes < 10 ? "0" : "")}$minutes";
}
