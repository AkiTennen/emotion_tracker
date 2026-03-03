import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable all features'),
            subtitle: const Text(
              'By default, the app introduces new layers of detail (like secondary emotions and intensity) gradually to help you stay focused on your feelings without overwhelm. Turn this on to access all features immediately.',
            ),
            isThreeLine: true,
            value: SettingsService.shouldSkipUnlocking(),
            onChanged: (bool value) async {
              await SettingsService.setSkipUnlocking(value);
              setState(() {});
            },
          ),
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
    );
  }
}
