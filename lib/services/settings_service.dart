import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class SettingsService {
  static const String settingsBoxName = 'settings';
  static const String skipUnlockingKey = 'skip_unlocking';

  static Future<void> init() async {
    await Hive.openBox(settingsBoxName);
  }

  static bool shouldSkipUnlocking() {
    final box = Hive.box(settingsBoxName);
    return box.get(skipUnlockingKey, defaultValue: false);
  }

  static Future<void> setSkipUnlocking(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(skipUnlockingKey, value);
  }
}
