import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import '../../services/settings_service.dart';
import '../../services/reminder_service.dart';
import '../../services/backup_service.dart';
import '../../models/emotion_data.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Reminder> _reminders = [];
  final List<TextEditingController> _controllers = [];
  late BodyType _currentBodyType;
  late ThemeMode _currentThemeMode;
  late int _firstDayOfWeek;
  late String _currentDateFormat;

  final List<String> _dateFormats = [
    'EEEE, MMMM d',
    'MMM d, yyyy',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadReminders();
    _currentBodyType = SettingsService.getBodyType();
    _currentThemeMode = SettingsService.getThemeMode();
    _firstDayOfWeek = SettingsService.getFirstDayOfWeek();
    _currentDateFormat = SettingsService.getDateFormat();
    ReminderService.requestPermissions();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    
    // Index 1: Reminders, Index 2: Colors, Index 3: Data
    if (_tabController.index == 1 && !SettingsService.isRemindersIntroShown()) {
      _showRemindersIntro();
    } else if (_tabController.index == 2 && !SettingsService.isColorsIntroShown()) {
      _showColorsIntro();
    } else if (_tabController.index == 3 && !SettingsService.isDataIntroShown()) {
      _showDataIntro();
    }
  }

  void _showRemindersIntro() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text('Daily Check-ins'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consistency is key to spotting patterns.', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _IntroPoint(
              icon: Icons.notifications_none,
              title: 'Quiet Mode',
              description: 'A standard notification. Respects your phone\'s silent settings.',
            ),
            _IntroPoint(
              icon: Icons.alarm,
              title: 'Alarm Mode',
              description: 'A persistent chime that bypasses silent mode. Great for ensuring you never miss a reflection.',
            ),
            _IntroPoint(
              icon: Icons.edit_notifications_outlined,
              title: 'Personalized Prompts',
              description: 'Change the message to whatever helps you pause and check in with yourself.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await SettingsService.setRemindersIntroShown(true);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showColorsIntro() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.palette_outlined, color: Colors.purple),
            SizedBox(width: 12),
            Text('Your Personal Palette'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emotions are personal, and so are their colors.', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _IntroPoint(
              icon: Icons.color_lens_outlined,
              title: 'Visual Meaning',
              description: 'Changing a color here updates your entire history. Pick colors that resonate with how you feel those emotions.',
            ),
            _IntroPoint(
              icon: Icons.calendar_view_month_outlined,
              title: 'Calendar Impact',
              description: 'Your "Emotion Pie Charts" on the calendar will immediately reflect these new colors.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await SettingsService.setColorsIntroShown(true);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showDataIntro() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage_outlined, color: Colors.blue),
            SizedBox(width: 12),
            Text('Data & Privacy'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You own your data. Always.', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _IntroPoint(
              icon: Icons.download_outlined,
              title: 'Backup Data',
              description: 'Creates a file in your "Downloads" folder. This contains your entire emotional history.',
            ),
            _IntroPoint(
              icon: Icons.upload_file_outlined,
              title: 'Restore Data',
              description: 'Use your backup file to restore your journey on a new device or after a re-install.',
            ),
            _IntroPoint(
              icon: Icons.security,
              title: 'Local Only',
              description: 'We never upload your data to a cloud. Your backup file is the only way to move your data.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await SettingsService.setDataIntroShown(true);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('I understand'),
          ),
        ],
      ),
    );
  }

  void _loadReminders() {
    _reminders = SettingsService.getReminders();
    for (var c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    for (var reminder in _reminders) {
      _controllers.add(TextEditingController(text: reminder.message));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveReminders() async {
    try {
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
      await SettingsService.saveReminders(updatedReminders);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminders saved and scheduled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reminders: ${e.toString()}')),
        );
      }
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
        isEnabled: true,
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

  void _showBodyTypePicker() {
    showDialog(
      context: context,
      builder: (context) {
        BodyType tempType = _currentBodyType;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Body Type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This changes the silhouette used in the body map.'),
                  const SizedBox(height: 16),
                  DropdownButton<BodyType>(
                    value: tempType,
                    isExpanded: true,
                    onChanged: (BodyType? newValue) {
                      if (newValue != null) {
                        setDialogState(() => tempType = newValue);
                      }
                    },
                    items: BodyType.values.map((BodyType type) {
                      return DropdownMenuItem<BodyType>(
                        value: type,
                        child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/body_maps/front_${tempType.name}.svg',
                              colorFilter: ColorFilter.mode(Theme.of(context).hintColor.withOpacity(0.3), BlendMode.srcIn),
                            ),
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/body_maps/back_${tempType.name}.svg',
                              colorFilter: ColorFilter.mode(Theme.of(context).hintColor.withOpacity(0.3), BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    await SettingsService.setBodyType(tempType);
                    setState(() => _currentBodyType = tempType);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _pickColor(String emotion) {
    final currentColors = SettingsService.getCustomColors();
    Color currentColor = EmotionData.getColor(emotion);
    if (currentColors.containsKey(emotion)) {
      currentColor = Color(currentColors[emotion]!);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick color for $emotion'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) => currentColor = color,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await SettingsService.setCustomColor(emotion, currentColor.value);
              setState(() {});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllUnlocked = SettingsService.shouldSkipUnlocking();
    final customColors = SettingsService.getCustomColors();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: General & Progression
          ListView(
            children: [
              _buildSectionHeader('APPEARANCE'),
              ListTile(
                title: const Text('Theme Mode'),
                subtitle: Text('Current: ${_currentThemeMode.name[0].toUpperCase() + _currentThemeMode.name.substring(1)}'),
                trailing: DropdownButton<ThemeMode>(
                  value: _currentThemeMode,
                  underline: const SizedBox(),
                  onChanged: (ThemeMode? newValue) async {
                    if (newValue != null) {
                      await SettingsService.setThemeMode(newValue);
                      setState(() => _currentThemeMode = newValue);
                      widget.onThemeChanged();
                    }
                  },
                  items: ThemeMode.values.map((ThemeMode mode) {
                    return DropdownMenuItem<ThemeMode>(
                      value: mode,
                      child: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
              _buildSectionHeader('LOCALIZATION'),
              ListTile(
                title: const Text('First Day of Week'),
                subtitle: Text('Current: ${_firstDayOfWeek == 1 ? "Monday" : "Sunday"}'),
                trailing: DropdownButton<int>(
                  value: _firstDayOfWeek,
                  underline: const SizedBox(),
                  onChanged: (int? newValue) async {
                    if (newValue != null) {
                      await SettingsService.setFirstDayOfWeek(newValue);
                      setState(() => _firstDayOfWeek = newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Monday')),
                    DropdownMenuItem(value: 7, child: Text('Sunday')),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Date Format'),
                subtitle: Text('Preview: ${DateFormat(_currentDateFormat).format(DateTime.now())}'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Date Format'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _dateFormats.map((format) {
                          return RadioListTile<String>(
                            title: Text(DateFormat(format).format(DateTime.now())),
                            value: format,
                            groupValue: _currentDateFormat,
                            onChanged: (String? value) async {
                              if (value != null) {
                                await SettingsService.setDateFormat(value);
                                setState(() => _currentDateFormat = value);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildSectionHeader('FEATURES'),
              SwitchListTile(
                title: const Text('Journaling'),
                subtitle: const Text('Enable separate space for long-form reflection.'),
                value: SettingsService.isJournalEnabled(),
                onChanged: (bool value) async {
                  await SettingsService.setJournalEnabled(value);
                  if (value) {
                    await SettingsService.setJournalHighlightPending(true);
                  }
                  setState(() {});
                },
              ),
              ListTile(
                title: const Text('Body Map Type'),
                subtitle: Text('Current: ${_currentBodyType.name[0].toUpperCase() + _currentBodyType.name.substring(1)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showBodyTypePicker,
              ),
              const Divider(),
              _buildSectionHeader('PROGRESSION & VISIBILITY'),
              SwitchListTile(
                title: const Text('Unlock Everything'),
                subtitle: const Text('Bypass all gradual feature unlocks.'),
                value: isAllUnlocked,
                onChanged: (bool value) async {
                  await SettingsService.setSkipUnlocking(value);
                  setState(() {});
                },
              ),
              Opacity(
                opacity: isAllUnlocked ? 0.5 : 1.0,
                child: AbsorbPointer(
                  absorbing: isAllUnlocked,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Secondary Emotions (Tier 2)'),
                        value: SettingsService.isTier2Unlocked(),
                        onChanged: (val) async {
                          await SettingsService.setTier2Unlocked(val);
                          setState(() {});
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Tertiary Emotions (Tier 3)'),
                        value: SettingsService.isTier3Unlocked(),
                        onChanged: (val) async {
                          await SettingsService.setTier3Unlocked(val);
                          setState(() {});
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Intensity Slider'),
                        value: SettingsService.isIntensityUnlocked(),
                        onChanged: (val) async {
                          await SettingsService.setIntensityUnlocked(val);
                          setState(() {});
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Body Map Feature'),
                        value: SettingsService.isBodyMapUnlocked(),
                        onChanged: (val) async {
                          await SettingsService.setBodyMapUnlocked(val);
                          setState(() {});
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Trigger Prompts'),
                        value: SettingsService.isTriggerPromptsUnlocked(),
                        onChanged: (val) async {
                          await SettingsService.setTriggerPromptsUnlocked(val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // TAB 2: Reminders
          ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_reminders.length < 3)
                      FilledButton.icon(
                        onPressed: _addReminder,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                  ],
                ),
              ),
              if (_reminders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('No reminders set.', style: TextStyle(color: Colors.grey))),
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
                            ActionChip(
                              avatar: const Icon(Icons.access_time, size: 16),
                              label: Text(reminder.time.format(context)),
                              onPressed: () => _pickTime(index),
                            ),
                            const Spacer(),
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
                              onPressed: () async {
                                final reminderId = reminder.id;
                                setState(() {
                                  _reminders.removeAt(index);
                                  _controllers.removeAt(index);
                                });
                                await SettingsService.saveReminders(List<Reminder>.from(_reminders));
                                await ReminderService.cancelReminder(reminderId);
                              },
                            ),
                          ],
                        ),
                        TextField(
                          controller: _controllers[index],
                          decoration: const InputDecoration(labelText: 'Prompt Message', isDense: true),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _AlertOption(
                                label: 'Quiet',
                                icon: Icons.notifications_none,
                                isSelected: reminder.alertType == AlertType.quiet,
                                onTap: () => setState(() => _reminders[index] = Reminder(id: reminder.id, time: reminder.time, alertType: AlertType.quiet, message: reminder.message, isEnabled: reminder.isEnabled)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _AlertOption(
                                label: 'Alarm',
                                icon: Icons.alarm,
                                isSelected: reminder.alertType == AlertType.alarm,
                                onTap: () => setState(() => _reminders[index] = Reminder(id: reminder.id, time: reminder.time, alertType: AlertType.alarm, message: reminder.message, isEnabled: reminder.isEnabled)),
                              ),
                            ),
                            if (reminder.alertType == AlertType.alarm)
                              IconButton(
                                icon: const Icon(Icons.play_circle_outline, size: 20),
                                onPressed: () => ReminderService.previewAlarmSound(),
                              ),
                            IconButton(
                              icon: const Icon(Icons.send_outlined, size: 20),
                              onPressed: () {
                                final test = Reminder(id: 999, time: reminder.time, alertType: reminder.alertType, message: _controllers[index].text, isEnabled: true);
                                ReminderService.sendImmediateTest(test);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_reminders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilledButton(
                    onPressed: _saveReminders,
                    child: const Text('Apply Reminder Changes'),
                  ),
                ),
            ],
          ),

          // TAB 3: Colors
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Personalize Emotions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      await SettingsService.resetCustomColors();
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset to Default'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Tap an emotion to change its primary color throughout the app.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: EmotionData.tier1.map((emotion) {
                  final color = customColors.containsKey(emotion) ? Color(customColors[emotion]!) : EmotionData.getColor(emotion);
                  return InkWell(
                    onTap: () => _pickColor(emotion),
                    child: Column(
                      children: [
                        CircleAvatar(backgroundColor: color, radius: 24),
                        const SizedBox(height: 4),
                        Text(emotion, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // TAB 4: Data & Advanced
          ListView(
            children: [
              _buildSectionHeader('DATA MANAGEMENT'),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Backup Data'),
                subtitle: const Text('Export all entries and settings.'),
                onTap: BackupService.exportBackup,
              ),
              ListTile(
                leading: const Icon(Icons.download_for_offline),
                title: const Text('Restore Data'),
                subtitle: const Text('Import data from a backup file.'),
                onTap: () async {
                  final success = await BackupService.importBackup();
                  if (success) {
                    setState(() {
                      _currentBodyType = SettingsService.getBodyType();
                      _firstDayOfWeek = SettingsService.getFirstDayOfWeek();
                      _currentDateFormat = SettingsService.getDateFormat();
                    });
                  }
                },
              ),
              const Divider(),
              _buildSectionHeader('ADVANCED & TUTORIALS'),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Show Welcome Onboarding'),
                subtitle: const Text('Replay the initial app introduction.'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OnboardingScreen(
                        onFinish: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reset In-App Tutorials'),
                subtitle: const Text('Show the body map and feature guides again.'),
                onTap: () async {
                  await SettingsService.setBodyMapIntroShown(false);
                  await SettingsService.setFirstEntryHintShown(false);
                  await SettingsService.setTier2IntroShown(false);
                  await SettingsService.setRemindersIntroShown(false);
                  await SettingsService.setColorsIntroShown(false);
                  await SettingsService.setDataIntroShown(false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutorials reset.')));
                },
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Privacy Note: Your emotional data is yours. It is stored locally and never leaves your device unless you export a backup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        child: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.settings_outlined)),
            Tab(text: 'Reminders', icon: Icon(Icons.notifications_outlined)),
            Tab(text: 'Colors', icon: Icon(Icons.palette_outlined)),
            Tab(text: 'Data', icon: Icon(Icons.storage_outlined)),
          ],
        ),
      ),
    );
  }
}

class _IntroPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _IntroPoint({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlertOption({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
