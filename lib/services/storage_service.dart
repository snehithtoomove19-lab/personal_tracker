import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for storing lists of JSON objects
/// and simple key/value settings. Kept intentionally simple (no external
/// database) so the project stays easy to read and run.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final p = await _p;
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> items) async {
    final p = await _p;
    await p.setString(key, jsonEncode(items));
  }

  Future<String?> readString(String key) async {
    final p = await _p;
    return p.getString(key);
  }

  Future<void> writeString(String key, String value) async {
    final p = await _p;
    await p.setString(key, value);
  }

  Future<bool?> readBool(String key) async {
    final p = await _p;
    return p.getBool(key);
  }

  Future<void> writeBool(String key, bool value) async {
    final p = await _p;
    await p.setBool(key, value);
  }

  Future<void> clearAll() async {
    final p = await _p;
    await p.clear();
  }
}

// Storage keys used across the app.
class StoreKeys {
  static const transactions = 'transactions';
  static const moods = 'moods';
  static const tasks = 'tasks';
  static const notes = 'notes';
  static const goals = 'goals';
  static const userName = 'userName';
  static const savingsGoal = 'savingsGoal';
  static const currency = 'currency';
  static const darkMode = 'darkMode';
  static const pin = 'appPin';
  static const pinEnabled = 'pinEnabled';
  static const lastOpenDate = 'lastOpenDate';
  static const streak = 'streak';
  static const budgets = 'categoryBudgets';
  static const showLaunchDigest = 'showLaunchDigest';
  static const birthday = 'birthday';
  static const birthdayContacts = 'birthdayContacts';
  static const aiApiKey = 'aiApiKey';
  static const aiModel = 'aiModel';
  static const chatHistory = 'chatHistory';
}
