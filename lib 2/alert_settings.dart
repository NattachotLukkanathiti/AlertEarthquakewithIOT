import 'package:shared_preferences/shared_preferences.dart';

class AlertSettings {
  static int dangerThreshold = 3;
  static int warningThreshold = 2;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    dangerThreshold = prefs.getInt("dangerThreshold") ?? 3;
    warningThreshold = prefs.getInt("warningThreshold") ?? 2;
  }

  static Future<void> save({
    required int danger,
    required int warning,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt("dangerThreshold", danger);
    await prefs.setInt("warningThreshold", warning);

    dangerThreshold = danger;
    warningThreshold = warning;
  }
}



