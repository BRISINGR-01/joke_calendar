// ignore_for_file: file_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joke_calendar/notificationservice.dart';
import 'package:joke_calendar/shared.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class DisplayEvent extends StatefulWidget {
  final int? id;
  final String time;
  final Function? addEvent;
  const DisplayEvent({Key? key, required this.time, this.id, this.addEvent})
      : super(key: key);

  @override
  DisplayEventState createState() => DisplayEventState();
}

class DisplayEventState extends State<DisplayEvent> {
  DataHelper db = DataHelper.init();

  late Event _event;
  late String title;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    tz.initializeTimeZones();
    if (widget.id is int) {
      _event = await db.getEventById(widget.id!);
    } else {
      _event = Event();
    }

    String month = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][_event.day.month];

    String ordinal(int number) {
      if (number >= 11 && number <= 13) {
        return 'th';
      }

      switch (number % 10) {
        case 1:
          return 'st';
        case 2:
          return 'nd';
        case 3:
          return 'rd';
        default:
          return 'th';
      }
    }

    setState(() {
      title = "${_event.day.day}${ordinal(_event.day.day)} $month";
      isLoaded = true;
    });
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
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (_event.id is int)
              IconButton(
                  onPressed: () async {
                    await db.deleteEvent(_event.id!);
                    NotificationService().cancel(_event.id!);
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.delete,
                  ))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            tz.TZDateTime scheduledDate = tz.TZDateTime.parse(tz.local,
                "${widget.time} ${formatTime(_event.timeSpan["start"]!)}:00");
            if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
              NotificationService().showNotification(
                _event.id!,
                _event.title,
                "${formatTime(_event.timeSpan["start"]!)} - ${formatTime(_event.timeSpan["end"]!)}",
                "${widget.time} ${formatTime(_event.timeSpan["start"]!)}:00",
                _event.image,
              );
            }

            await db.saveEvent(_event);
            if (mounted) Navigator.pop(context);
          },
          child: const Icon(Icons.done),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                  autofocus: true,
                  initialValue: _event.title,
                  onChanged: (value) {
                    _event.title = value;
                  }),
            ),
            PersonWidget(
              setImage: (path) => setState(() {
                _event.image = path;
              }),
              photo: _event.image,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    int hour = _event.timeSpan["start"]!.truncate();
                    int minites = ((_event.timeSpan["start"]! -
                                _event.timeSpan["start"]!.truncate()) *
                            100)
                        .round();
                    TimeOfDay? newTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: hour, minute: minites),
                    );
                    if (newTime != null) {
                      setState(() {
                        _event.timeSpan["start"] = newTime.hour.toDouble() +
                            newTime.minute.toDouble() / 100;
                        if (_event.timeSpan["start"]! >
                            _event.timeSpan["end"]!) {
                          _event.timeSpan["end"] = _event.timeSpan["start"]!;
                        }
                      });
                    }
                  },
                  child: Text(
                    formatTime(_event.timeSpan["start"] as double),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_forward),
                ),
                ElevatedButton(
                  onPressed: () async {
                    int hour = _event.timeSpan["end"]!.truncate();
                    int minites = ((_event.timeSpan["end"]! -
                                _event.timeSpan["end"]!.truncate()) *
                            100)
                        .round();
                    TimeOfDay? newTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: hour, minute: minites),
                    );
                    if (newTime != null) {
                      setState(() {
                        _event.timeSpan["end"] = newTime.hour.toDouble() +
                            newTime.minute.toDouble() / 100;
                      });
                      if (_event.timeSpan["start"]! > _event.timeSpan["end"]!) {
                        _event.timeSpan["start"] = _event.timeSpan["end"]!;
                      }
                    }
                  },
                  child: Text(
                    formatTime(_event.timeSpan["end"] as double),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class PersonWidget extends StatefulWidget {
  final String? photo;
  final Function setImage;
  const PersonWidget({Key? key, required this.setImage, this.photo})
      : super(key: key);

  @override
  PersonWidgetState createState() => PersonWidgetState();
}

class PersonWidgetState extends State<PersonWidget> {
  XFile? _image;
  String? _imagePath;
  bool _isImagePathCorrect = false;

  @override
  void initState() {
    super.initState();
    if (widget.photo != null) _imagePath = widget.photo;
    File(_imagePath ?? "").exists().then((value) => setState(() {
          _isImagePathCorrect = value;
        }));
  }

  Future getImage() async {
    bool? isCamera = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.photo_camera),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Camera"),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.photo_library_outlined),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Gallery"),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isCamera == null) return;

    ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: isCamera ? 1 : 10);
    if (image == null) return;

    setState(() {
      _imagePath = image.path;
      _image = image;
      _isImagePathCorrect;
    });

    await Future.delayed(const Duration()); // a magical fix ¯\_(ツ)_/¯

    setState(() {
      _imagePath = _image?.path;
      _image = image;
    });
    widget.setImage(_imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: getImage,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 2.5,
            ),
            shape: BoxShape.circle,
          ),
          child: _isImagePathCorrect
              ? CircleAvatar(
                  backgroundImage: FileImage(File(_imagePath!)),
                  radius: 60,
                )
              : CircleAvatar(
                  backgroundColor: Colors.blue[200],
                  radius: 60,
                  child: const Icon(Icons.person),
                ),
        ));
  }
}
