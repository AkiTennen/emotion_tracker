import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../services/reminder_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Reminder> _reminders = [];
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
    // Proactively request permissions for background alarms
    ReminderService.requestPermissions();
  }

  void _loadReminders() {
    _reminders = SettingsService.getReminders();
    for (var reminder in _reminders) {
      _controllers.add(TextEditingController(text: reminder.message));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveReminders() async {
    // 1. Sync controller text to reminder objects
    final updatedReminders = <Reminder>[];
    for (int i = 0; i < _reminders.length; i++) {
      updatedReminders.add(Reminder(
        id: _reminders[i].id,
        time: _reminders[i].time,
        alertType: _reminders[i].alertType,
        message: _controllers[i].text,
        isEnabled: _reminders[i].isEnabled,
      ));
    }

    // 2. Save to database & schedule alarms
    await SettingsService.saveReminders(updatedReminders);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminders saved and scheduled')),
      );
    }
  }

  void _addReminder() {
    if (_reminders.length >= 3) return;
    
    setState(() {
      final newReminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        time: const TimeOfDay(hour: 8, minute: 0),
        alertType: AlertType.quiet,
        message: 'How are you feeling right now?',
      );
      _reminders.add(newReminder);
      _controllers.add(TextEditingController(text: newReminder.message));
    });
  }

  Future<void> _pickTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminders[index].time,
    );
    if (picked != null) {
      setState(() {
        _reminders[index] = Reminder(
          id: _reminders[index].id,
          time: picked,
          alertType: _reminders[index].alertType,
          message: _reminders[index].message,
          isEnabled: _reminders[index].isEnabled,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100), // Space for FAB
        children: [
          SwitchListTile(
            title: const Text('Enable all features'),
            subtitle: const Text(
              'By default, the app introduces new layers of detail gradually. Turn this on to access all features immediately.',
            ),
            isThreeLine: true,
            value: SettingsService.shouldSkipUnlocking(),
            onChanged: (bool value) async {
              await SettingsService.setSkipUnlocking(value);
              setState(() {});
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Reminders', style: Theme.of(context).textTheme.titleLarge),
                if (_reminders.length < 3)
                  ElevatedButton.icon(
                    onPressed: _addReminder,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
              ],
            ),
          ),
          if (_reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('No reminders set. Use them to build a mindful habit.', style: TextStyle(color: Colors.grey)),
            ),
          ..._reminders.asMap().entries.map((entry) {
            final index = entry.key;
            final reminder = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _pickTime(index),
                          child: Text(
                            reminder.time.format(context),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const Spacer(),
                        // Instant Test Button
                        TextButton.icon(
                          onPressed: () {
                            final testReminder = Reminder(
                              id: 999,
                              time: reminder.time,
                              alertType: reminder.alertType,
                              message: _controllers[index].text,
                              isEnabled: true,
                            );
                            ReminderService.sendImmediateTest(testReminder);
                          },
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Test'),
                        ),
                        Switch(
                          value: reminder.isEnabled,
                          onChanged: (val) {
                            setState(() {
                              _reminders[index] = Reminder(
                                id: reminder.id,
                                time: reminder.time,
                                alertType: reminder.alertType,
                                message: reminder.message,
                                isEnabled: val,
                              );
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _reminders.removeAt(index);
                              _controllers[index].dispose();
                              _controllers.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers[index],
                      decoration: const InputDecoration(
                        labelText: 'What should the app ask you?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _AlertOption(
                          label: 'Quiet',
                          icon: Icons.notifications_none,
                          isSelected: reminder.alertType == AlertType.quiet,
                          onTap: () => setState(() {
                            _reminders[index] = Reminder(
                              id: reminder.id,
                              time: reminder.time,
                              alertType: AlertType.quiet,
                              message: reminder.message,
                              isEnabled: reminder.isEnabled,
                            );
                          }),
                        ),
                        _AlertOption(
                          label: 'Vibrate',
                          icon: Icons.vibration,
                          isSelected: reminder.alertType == AlertType.vibrate,
                          onTap: () => setState(() {
                            _reminders[index] = Reminder(
                              id: reminder.id,
                              time: reminder.time,
                              alertType: AlertType.vibrate,
                              message: reminder.message,
                              isEnabled: reminder.isEnabled,
                            );
                          }),
                        ),
                        _AlertOption(
                          label: 'Alarm',
                          icon: Icons.alarm,
                          isSelected: reminder.alertType == AlertType.alarm,
                          onTap: () => setState(() {
                            _reminders[index] = Reminder(
                              id: reminder.id,
                              time: reminder.time,
                              alertType: AlertType.alarm,
                              message: reminder.message,
                              isEnabled: reminder.isEnabled,
                            );
                          }),
                        ),
                        if (reminder.alertType == AlertType.alarm)
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline),
                            onPressed: () => ReminderService.previewAlarmSound(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Privacy Note: All your emotional data is stored locally on this device. No data ever leaves your phone.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveReminders,
        label: const Text('Save Reminders'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}

class _AlertOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlertOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          border: isSelected ? Border.all(color: Theme.of(context).primaryColor) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
            Text(label, style: TextStyle(
              fontSize: 12,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            )),
          ],
        ),
      ),
    );
  }
}
