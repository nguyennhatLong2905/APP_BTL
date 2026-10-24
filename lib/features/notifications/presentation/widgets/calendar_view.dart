import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/timeline_item.dart';

class CalendarViewWidget extends StatefulWidget {
  final List<TimelineItem> items;
  final ValueChanged<DateTime> onDaySelected;

  const CalendarViewWidget({
    super.key,
    required this.items,
    required this.onDaySelected,
  });

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<TimelineItem> _getEventsForDay(DateTime day) {
    return widget.items.where((item) {
      if (item.dateTime == null) return false;
      return item.dateTime!.year == day.year &&
          item.dateTime!.month == day.month &&
          item.dateTime!.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: TableCalendar<TimelineItem>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        eventLoader: _getEventsForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDaySelected(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF00A86B),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
