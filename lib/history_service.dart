import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _key = 'scan_history';

  static Future<void> saveToHistory(String data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    // Duplicate এড়াতে
    history.remove(data);
    history.insert(0, data);
    // সর্বোচ্চ 100টি রাখবে
    if (history.length > 100) history = history.sublist(0, 100);
    await prefs.setStringList(_key, history);
  }

  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> deleteItem(String data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    history.remove(data);
    await prefs.setStringList(_key, history);
  }
}