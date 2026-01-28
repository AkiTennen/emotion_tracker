import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// The main screen of the application, featuring a calendar view.
///
/// It displays a calendar and allows the user to select a date.
/// An "add" button appears only when a date is selected, prompting
/// the user to create a new entry for that day.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // The currently selected day in the calendar. Null if no day is selected.
  DateTime? _selectedDay;

  // The day that the calendar is currently focused on (e.g., the current month).
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Emotions'),
      ),
      body: Column(
        children: [
          TableCalendar(
            // The first day the user can select (e.g., 2 years in the past).
            firstDay: DateTime.utc(DateTime.now().year - 2, 1, 1),
            // The last day the user can select (today).
            lastDay: DateTime.now(),
            // The day that is currently focused.
            focusedDay: _focusedDay,
            // The format of the calendar (e.g., month view).
            calendarFormat: CalendarFormat.month,
            // What happens when a user taps on a day.
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // Update focused day as well
              });
            },
            // A function to determine if a day is currently selected.
            // This is used to style the selected day differently.
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            // --- STYLING ---
            calendarStyle: CalendarStyle(
              // Style for the marker on the currently selected day.
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              // Style for the marker on today's date.
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              // Display the month and year, and hide the format button.
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),
          const Divider(),
          // TODO: We will display the list of entries for the selected day here.
        ],
      ),
      // The floating action button to add a new entry.
      // It is only visible if a day has been selected.
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to the "Add Emotion" screen for the _selectedDay.
          print('Add entry for: $_selectedDay');
        },
        tooltip: 'Add Emotion',
        child: const Icon(Icons.add),
      )
          : null, // If no day is selected, show no button.
    );
  }
}