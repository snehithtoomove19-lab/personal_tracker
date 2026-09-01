import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/mood_entry.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/goal.dart';
import '../models/birthday_contact.dart';
import '../models/chat_message.dart';
import 'storage_service.dart';

const _uuid = Uuid();

const List<String> kDefaultExpenseCategories = [
  'Food',
  'Transport',
  'Shopping',
  'Bills',
  'Health',
  'Entertainment',
  'Education',
  'Other',
];
const List<String> kDefaultIncomeCategories = [
  'Salary',
  'Allowance',
  'Gift',
  'Freelance',
  'Other',
];

const List<String> kMotivationalQuotes = [
  "Small steps every day add up to big results.",
  "Track it to master it.",
  "A penny saved, tracked, and understood is a penny earned twice.",
  "Progress, not perfection.",
  "Your future self will thank you for today's discipline.",
  "Consistency beats intensity.",
  "Every entry you log is a step toward clarity.",
  "Mood, money, and tasks Ã¢â‚¬â€ small logs, big awareness.",
];

class AppState extends ChangeNotifier {
  final List<AppTransaction> transactions = [];
  final List<MoodEntry> moods = [];
  final List<AppTask> tasks = [];
  final List<AppNote> notes = [];
  final List<AppGoal> goals = [];
  final List<String> customExpenseCategories = [];
  final List<String> customIncomeCategories = [];
  final Map<String, double> categoryBudgets = {};

  String userName = 'Friend';
  double savingsGoal = 0;
  String currency = 'Ã¢â€šÂ¹';
  bool darkMode = false;
  bool pinEnabled = false;
  String? pin;
  int streak = 0;
  bool showLaunchDigest = true;
  DateTime? birthday;
  final List<BirthdayContact> birthdayContacts = [];
  String aiApiKey = '';
  String aiModel = 'gpt-4o-mini';
  final List<ChatMessage> chatMessages = [];

  bool _loaded = false;
  bool get loaded => _loaded;

  /// Marks the app as loaded without going through the normal [load]
  /// sequence Ã¢â‚¬â€ used as a fallback if loading saved data throws, so the UI
  /// can still open (with whatever defaults are already set) instead of
  /// being stuck on a loading spinner forever.
  void forceMarkLoaded() {
    _loaded = true;
    notifyListeners();
  }

  List<String> get expenseCategories =>
      [...kDefaultExpenseCategories, ...customExpenseCategories];
  List<String> get incomeCategories =>
      [...kDefaultIncomeCategories, ...customIncomeCategories];

  Future<void> load() async {
    final s = StorageService.instance;

    Future<void> safely(String label, Future<void> Function() action) async {
      try {
        await action();
      } catch (e, st) {
        // A single corrupted saved record should never permanently block
        // the app from opening. Log it and move on with whatever loaded
        // successfully so far Ã¢â‚¬â€ this section just falls back to empty/
        // default rather than taking the whole app down.
        debugPrint('Failed to load $label: $e\n$st');
      }
    }

    await safely('transactions', () async {
      final txJson = await s.readList(StoreKeys.transactions);
      final loaded = <AppTransaction>[];
      for (final j in txJson) {
        try {
          loaded.add(AppTransaction.fromJson(j));
        } catch (_) {}
      }
      transactions
        ..clear()
        ..addAll(loaded);
    });

    await safely('moods', () async {
      final moodJson = await s.readList(StoreKeys.moods);
      final loaded = <MoodEntry>[];
      for (final j in moodJson) {
        try {
          loaded.add(MoodEntry.fromJson(j));
        } catch (_) {}
      }
      moods
        ..clear()
        ..addAll(loaded);
    });

    await safely('tasks', () async {
      final taskJson = await s.readList(StoreKeys.tasks);
      final loaded = <AppTask>[];
      for (final j in taskJson) {
        try {
          loaded.add(AppTask.fromJson(j));
        } catch (_) {}
      }
      tasks
        ..clear()
        ..addAll(loaded);
    });

    await safely('notes', () async {
      final noteJson = await s.readList(StoreKeys.notes);
      final loaded = <AppNote>[];
      for (final j in noteJson) {
        try {
          loaded.add(AppNote.fromJson(j));
        } catch (_) {}
      }
      notes
        ..clear()
        ..addAll(loaded);
    });

    await safely('goals', () async {
      final goalJson = await s.readList(StoreKeys.goals);
      final loaded = <AppGoal>[];
      for (final j in goalJson) {
        try {
          loaded.add(AppGoal.fromJson(j));
        } catch (_) {}
      }
      goals
        ..clear()
        ..addAll(loaded);
    });

    await safely('settings', () async {
      userName = await s.readString(StoreKeys.userName) ?? 'Friend';
      currency = await s.readString(StoreKeys.currency) ?? 'Ã¢â€šÂ¹';
      darkMode = await s.readBool(StoreKeys.darkMode) ?? false;
      pinEnabled = await s.readBool(StoreKeys.pinEnabled) ?? false;
      pin = await s.readString(StoreKeys.pin);
      final savingsStr = await s.readString(StoreKeys.savingsGoal);
      savingsGoal = savingsStr != null ? double.tryParse(savingsStr) ?? 0 : 0;
    });

    await safely('budgets', () async {
      final budgetsRaw = await s.readString(StoreKeys.budgets);
      categoryBudgets.clear();
      if (budgetsRaw != null && budgetsRaw.isNotEmpty) {
        final decoded = jsonDecode(budgetsRaw) as Map<String, dynamic>;
        decoded.forEach((k, v) => categoryBudgets[k] = (v as num).toDouble());
      }
    });

    await safely('launch digest setting', () async {
      showLaunchDigest = await s.readBool(StoreKeys.showLaunchDigest) ?? true;
    });

    await safely('birthday', () async {
      final birthdayStr = await s.readString(StoreKeys.birthday);
      birthday = birthdayStr != null ? DateTime.tryParse(birthdayStr) : null;
    });

    await safely('birthday contacts', () async {
      final contactsJson = await s.readList(StoreKeys.birthdayContacts);
      birthdayContacts
        ..clear()
        ..addAll(contactsJson.map((e) => BirthdayContact.fromJson(e)));
    });

    await safely('AI settings', () async {
      aiApiKey = await s.readString(StoreKeys.aiApiKey) ?? '';
      aiModel = await s.readString(StoreKeys.aiModel) ?? 'gpt-4o-mini';
    });

    await safely('chat history', () async {
      final chatJson = await s.readList(StoreKeys.chatHistory);
      final loaded = <ChatMessage>[];
      for (final j in chatJson) {
        try {
          loaded.add(ChatMessage.fromJson(j));
        } catch (_) {}
      }
      chatMessages
        ..clear()
        ..addAll(loaded);
    });

    await safely(
        'recurring transactions', () => _processRecurringTransactions());
    await safely('streak', () => _updateStreak());

    _loaded = true;
    notifyListeners();
  }

  Future<void> _updateStreak() async {
    final s = StorageService.instance;
    final lastStr = await s.readString(StoreKeys.lastOpenDate);
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    int currentStreak = await _readStreak();

    if (lastStr == null) {
      currentStreak = _hasLogToday() ? 1 : 0;
    } else {
      final last = DateTime.tryParse(lastStr);
      if (last != null) {
        final diff = DateTime(today.year, today.month, today.day)
            .difference(DateTime(last.year, last.month, last.day))
            .inDays;
        if (diff == 0) {
          // same day, keep streak
        } else if (diff == 1 && _hasLogToday()) {
          currentStreak += 1;
        } else if (diff > 1) {
          currentStreak = _hasLogToday() ? 1 : 0;
        }
      }
    }
    streak = currentStreak;
    await s.writeString(StoreKeys.lastOpenDate, todayKey);
    await s.writeString(StoreKeys.streak, streak.toString());
  }

  Future<int> _readStreak() async {
    final raw = await StorageService.instance.readString(StoreKeys.streak);
    return raw != null ? int.tryParse(raw) ?? 0 : 0;
  }

  bool _hasLogToday() {
    final now = DateTime.now();
    final hasTx = transactions.any((t) => _isSameDay(t.date, now));
    final hasMood = moods.any((m) => _isSameDay(m.date, now));
    return hasTx || hasMood;
  }

  String _dateKey(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------------- Transactions ----------------
  Future<void> addTransaction(AppTransaction t) async {
    transactions.insert(0, t);
    await _saveTransactions();
    await _updateStreak();
    notifyListeners();
  }

  Future<void> updateTransaction(AppTransaction t) async {
    final idx = transactions.indexWhere((e) => e.id == t.id);
    if (idx != -1) transactions[idx] = t;
    await _saveTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((e) => e.id == id);
    await _saveTransactions();
    notifyListeners();
  }

  Future<void> _saveTransactions() => StorageService.instance.writeList(
      StoreKeys.transactions, transactions.map((e) => e.toJson()).toList());

  /// On each app open, catches up any recurring transactions (e.g. monthly
  /// rent, weekly allowance) that are due, by finding the latest entry in
  /// each recurring "series" and adding new occurrences up to today. Capped
  /// per series so a long-unused app doesn't flood the list.
  Future<void> _processRecurringTransactions() async {
    final series =
        transactions.where((t) => t.repeat != TxRepeat.none).toList();
    if (series.isEmpty) return;

    final seen = <String>{};
    final newEntries = <AppTransaction>[];
    final today = DateTime.now();

    for (final t in series) {
      final key =
          '${t.type.name}|${t.category}|${t.amount}|${t.paymentMethod}|${t.repeat.name}';
      if (seen.contains(key)) continue;
      seen.add(key);

      final sameSeries = series.where((e) =>
          '${e.type.name}|${e.category}|${e.amount}|${e.paymentMethod}|${e.repeat.name}' ==
          key);
      var latest = sameSeries.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

      var guard = 0;
      while (guard < 24) {
        final next = latest.repeat == TxRepeat.weekly
            ? latest.date.add(const Duration(days: 7))
            : DateTime(
                latest.date.year, latest.date.month + 1, latest.date.day);
        if (next.isAfter(today)) break;
        final created = AppTransaction(
          id: newId(),
          type: latest.type,
          amount: latest.amount,
          category: latest.category,
          note: latest.note,
          date: next,
          paymentMethod: latest.paymentMethod,
          repeat: latest.repeat,
        );
        newEntries.add(created);
        latest = created;
        guard++;
      }
    }

    if (newEntries.isNotEmpty) {
      transactions.insertAll(0, newEntries);
      await _saveTransactions();
    }
  }

  double get totalBalance {
    double bal = 0;
    for (final t in transactions) {
      bal += t.type == TxType.income ? t.amount : -t.amount;
    }
    return bal;
  }

  double get todayExpense => _sumExpense(
      transactions.where((t) => _isSameDay(t.date, DateTime.now())));
  double get monthExpense {
    final now = DateTime.now();
    return _sumExpense(transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month));
  }

  double get monthIncome {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == TxType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (p, e) => p + e.amount);
  }

  /// Average net savings (income - expense) per calendar month, computed
  /// over however many of the last 6 months actually have transactions.
  /// Returns 0 if there's no data yet.
  double get averageMonthlyNetSavings {
    final now = DateTime.now();
    final monthlyTotals = <String, double>{};
    for (int i = 0; i < 6; i++) {
      final m = DateTime(now.year, now.month - i);
      monthlyTotals['${m.year}-${m.month}'] = 0;
    }
    for (final t in transactions) {
      final key = '${t.date.year}-${t.date.month}';
      if (monthlyTotals.containsKey(key)) {
        monthlyTotals[key] = monthlyTotals[key]! +
            (t.type == TxType.income ? t.amount : -t.amount);
      }
    }
    final monthsWithData = monthlyTotals.values.where((v) => v != 0).toList();
    if (monthsWithData.isEmpty) return 0;
    return monthsWithData.fold(0.0, (p, e) => p + e) / monthsWithData.length;
  }

  /// Estimated whole months until [savingsGoal] is reached at the current
  /// average monthly savings rate. Null if there's no goal set, the goal is
  /// already met, or the average rate isn't positive (so it would never be
  /// reached).
  int? get monthsToReachSavingsGoal {
    if (savingsGoal <= 0) return null;
    final remaining = savingsGoal - totalBalance;
    if (remaining <= 0) return 0;
    final rate = averageMonthlyNetSavings;
    if (rate <= 0) return null;
    return (remaining / rate).ceil();
  }

  double _sumExpense(Iterable<AppTransaction> items) => items
      .where((t) => t.type == TxType.expense)
      .fold(0.0, (p, e) => p + e.amount);

  Map<String, double> categorySpending({DateTime? month}) {
    final m = month ?? DateTime.now();
    final map = <String, double>{};
    for (final t in transactions.where((t) =>
        t.type == TxType.expense &&
        t.date.year == m.year &&
        t.date.month == m.month)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  String? get highestSpendingCategory {
    final map = categorySpending();
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  double get weekExpense {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _sumExpense(transactions.where((t) => !t.date.isBefore(start)));
  }

  /// Total expense for each of the last [days] days, oldest first, ending
  /// today. Used to draw the spending trend chart on Reports.
  List<double> dailyExpenseTrend({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totals = List<double>.filled(days, 0);
    for (final t in transactions.where((t) => t.type == TxType.expense)) {
      final txDay = DateTime(t.date.year, t.date.month, t.date.day);
      final diff = today.difference(txDay).inDays;
      if (diff >= 0 && diff < days) {
        totals[days - 1 - diff] += t.amount;
      }
    }
    return totals;
  }

  /// Breakdown of this month's expenses by payment method.
  Map<String, double> paymentMethodSpending({DateTime? month}) {
    final m = month ?? DateTime.now();
    final map = <String, double>{};
    for (final t in transactions.where((t) =>
        t.type == TxType.expense &&
        t.date.year == m.year &&
        t.date.month == m.month)) {
      map[t.paymentMethod] = (map[t.paymentMethod] ?? 0) + t.amount;
    }
    return map;
  }

  // ---------------- Budgets ----------------
  Future<void> setCategoryBudget(String category, double amount) async {
    if (amount <= 0) {
      categoryBudgets.remove(category);
    } else {
      categoryBudgets[category] = amount;
    }
    await StorageService.instance
        .writeString(StoreKeys.budgets, jsonEncode(categoryBudgets));
    notifyListeners();
  }

  /// Categories in the current month that have exceeded their set budget.
  /// Returns category -> (spent, budget).
  Map<String, List<double>> get overBudgetCategories {
    final spending = categorySpending();
    final result = <String, List<double>>{};
    for (final entry in categoryBudgets.entries) {
      final spent = spending[entry.key] ?? 0;
      if (spent > entry.value) {
        result[entry.key] = [spent, entry.value];
      }
    }
    return result;
  }

  double get lastMonthExpense {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return _sumExpense(transactions.where((t) =>
        t.date.year == lastMonth.year && t.date.month == lastMonth.month));
  }

  /// Percentage change of this month's spending vs last month's. Null if
  /// there's no data for last month to compare against.
  double? get monthOverMonthChangePercent {
    final last = lastMonthExpense;
    if (last == 0) return null;
    return ((monthExpense - last) / last) * 100;
  }

  // ---------------- Moods ----------------
  Future<void> upsertMood(MoodEntry m) async {
    final idx = moods.indexWhere((e) => MoodEntry.isSameDay(e.date, m.date));
    if (idx != -1) {
      moods[idx] = m;
    } else {
      moods.add(m);
    }
    await _saveMoods();
    await _updateStreak();
    notifyListeners();
  }

  Future<void> deleteMood(String id) async {
    moods.removeWhere((e) => e.id == id);
    await _saveMoods();
    notifyListeners();
  }

  Future<void> _saveMoods() => StorageService.instance
      .writeList(StoreKeys.moods, moods.map((e) => e.toJson()).toList());

  MoodEntry? moodForDay(DateTime day) {
    try {
      return moods.firstWhere((m) => MoodEntry.isSameDay(m.date, day));
    } catch (_) {
      return null;
    }
  }

  MoodEntry? get todayMood => moodForDay(DateTime.now());

  Future<void> setShowLaunchDigest(bool value) async {
    showLaunchDigest = value;
    await StorageService.instance.writeBool(StoreKeys.showLaunchDigest, value);
    notifyListeners();
  }

  Future<void> setBirthday(DateTime? date) async {
    birthday = date;
    if (date != null) {
      await StorageService.instance
          .writeString(StoreKeys.birthday, date.toIso8601String());
    }
    notifyListeners();
  }

  Future<void> addBirthdayContact(BirthdayContact contact) async {
    birthdayContacts.add(contact);
    await _saveBirthdayContacts();
    notifyListeners();
  }

  Future<void> updateBirthdayContact(BirthdayContact contact) async {
    final idx = birthdayContacts.indexWhere((e) => e.id == contact.id);
    if (idx != -1) {
      birthdayContacts[idx] = contact;
      await _saveBirthdayContacts();
      notifyListeners();
    }
  }

  Future<void> deleteBirthdayContact(String id) async {
    birthdayContacts.removeWhere((e) => e.id == id);
    await _saveBirthdayContacts();
    notifyListeners();
  }

  Future<void> _saveBirthdayContacts() => StorageService.instance.writeList(
        StoreKeys.birthdayContacts,
        birthdayContacts.map((e) => e.toJson()).toList(),
      );

  /// Age in whole years as of today. Null if no birthday is set.
  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int years = now.year - birthday!.year;
    final hadBirthdayThisYear = (now.month > birthday!.month) ||
        (now.month == birthday!.month && now.day >= birthday!.day);
    if (!hadBirthdayThisYear) years--;
    return years;
  }

  Future<void> setAiApiKey(String key) async {
    aiApiKey = key;
    await StorageService.instance.writeString(StoreKeys.aiApiKey, key);
    notifyListeners();
  }

  Future<void> setAiModel(String model) async {
    aiModel = model;
    await StorageService.instance.writeString(StoreKeys.aiModel, model);
    notifyListeners();
  }

  bool get isMyBirthdayToday {
    if (birthday == null) return false;
    final now = DateTime.now();
    return birthday!.month == now.month && birthday!.day == now.day;
  }

  List<BirthdayContact> get todayBirthdayContacts {
    final now = DateTime.now();
    return birthdayContacts.where((c) => c.daysUntil(now) == 0).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  bool get hasBirthdayToday =>
      isMyBirthdayToday || todayBirthdayContacts.isNotEmpty;

  /// A quick "what needs your attention" summary computed entirely from
  /// data already on-device Ã¢â‚¬â€ shown once per app open as a lightweight
  /// substitute for push notifications (which need native platform setup).
  LaunchDigest get launchDigest => LaunchDigest(
        overdueTaskCount: overdueTasks.length,
        todayTaskCount: todayTasks.length,
        moodLoggedToday: todayMood != null,
        missedMoodDays: missedMoodDaysThisMonth.length,
        overBudgetCategoryCount: overBudgetCategories.length,
      );

  /// Days so far this month (up to yesterday) that have no mood entry Ã¢â‚¬â€
  /// used to nudge the person to keep every day logged.
  List<DateTime> get missedMoodDaysThisMonth {
    final now = DateTime.now();
    final missed = <DateTime>[];
    for (int day = 1; day < now.day; day++) {
      final date = DateTime(now.year, now.month, day);
      if (moodForDay(date) == null) missed.add(date);
    }
    return missed;
  }

  Map<String, int> monthMoodSummary({DateTime? month}) {
    final m = month ?? DateTime.now();
    final map = <String, int>{};
    for (final mo in moods
        .where((e) => e.date.year == m.year && e.date.month == m.month)) {
      map[mo.mood] = (map[mo.mood] ?? 0) + 1;
    }
    return map;
  }

  // ---------------- Tasks ----------------
  Future<void> addTask(AppTask t) async {
    tasks.insert(0, t);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTask(AppTask t) async {
    final idx = tasks.indexWhere((e) => e.id == t.id);
    if (idx != -1) tasks[idx] = t;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    final idx = tasks.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final task = tasks[idx];
      final justCompleted = !task.completed;
      task.completed = justCompleted;

      // If a repeating task was just completed, spin up its next occurrence
      // automatically (e.g. "Water plants" daily, "Pay rent" monthly).
      if (justCompleted && task.repeat != TaskRepeat.none) {
        final nextDue =
            _nextDueDate(task.dueDate ?? DateTime.now(), task.repeat);
        final nextTask = AppTask(
          id: newId(),
          title: task.title,
          description: task.description,
          dueDate: nextDue,
          dueTimeMinutes: task.dueTimeMinutes,
          createdAt: DateTime.now(),
          priority: task.priority,
          category: task.category,
          repeat: task.repeat,
          reminderEnabled: task.reminderEnabled,
        );
        tasks.insert(idx, nextTask);
      }

      await _saveTasks();
      notifyListeners();
    }
  }

  DateTime _nextDueDate(DateTime from, TaskRepeat repeat) {
    switch (repeat) {
      case TaskRepeat.daily:
        return from.add(const Duration(days: 1));
      case TaskRepeat.weekly:
        return from.add(const Duration(days: 7));
      case TaskRepeat.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case TaskRepeat.none:
        return from;
    }
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((e) => e.id == id);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> _saveTasks() => StorageService.instance
      .writeList(StoreKeys.tasks, tasks.map((e) => e.toJson()).toList());

  List<AppTask> get todayTasks {
    final now = DateTime.now();
    return tasks
        .where((t) =>
            !t.completed && t.dueDate != null && _isSameDay(t.dueDate!, now))
        .toList();
  }

  List<AppTask> get overdueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks
        .where((t) =>
            !t.completed && t.dueDate != null && t.dueDate!.isBefore(today))
        .toList();
  }

  // ---------------- Notes ----------------
  Future<void> addNote(AppNote n) async {
    notes.insert(0, n);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> updateNote(AppNote n) async {
    final idx = notes.indexWhere((e) => e.id == n.id);
    if (idx != -1) notes[idx] = n;
    await _saveNotes();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    notes.removeWhere((e) => e.id == id);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> _saveNotes() => StorageService.instance
      .writeList(StoreKeys.notes, notes.map((e) => e.toJson()).toList());

  // ---------------- Goals ----------------
  Future<void> addGoal(AppGoal g) async {
    goals.insert(0, g);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> updateGoal(AppGoal g) async {
    final idx = goals.indexWhere((e) => e.id == g.id);
    if (idx != -1) goals[idx] = g;
    await _saveGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((e) => e.id == id);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> _saveGoals() => StorageService.instance
      .writeList(StoreKeys.goals, goals.map((e) => e.toJson()).toList());

  // ---------------- Settings ----------------
  Future<void> setUserName(String name) async {
    userName = name;
    await StorageService.instance.writeString(StoreKeys.userName, name);
    notifyListeners();
  }

  Future<void> setSavingsGoal(double amount) async {
    savingsGoal = amount;
    await StorageService.instance
        .writeString(StoreKeys.savingsGoal, amount.toString());
    notifyListeners();
  }

  Future<void> setCurrency(String c) async {
    currency = c;
    await StorageService.instance.writeString(StoreKeys.currency, c);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    darkMode = v;
    await StorageService.instance.writeBool(StoreKeys.darkMode, v);
    notifyListeners();
  }

  Future<void> setPin(String? newPin) async {
    pin = newPin;
    pinEnabled = newPin != null;
    await StorageService.instance.writeBool(StoreKeys.pinEnabled, pinEnabled);
    if (newPin != null) {
      await StorageService.instance.writeString(StoreKeys.pin, newPin);
    }
    notifyListeners();
  }

  Future<void> addCustomCategory(String name, {required bool isExpense}) async {
    if (isExpense) {
      if (!customExpenseCategories.contains(name)) {
        customExpenseCategories.add(name);
      }
    } else {
      if (!customIncomeCategories.contains(name)) {
        customIncomeCategories.add(name);
      }
    }
    notifyListeners();
  }

  Future<void> clearAllData() async {
    transactions.clear();
    moods.clear();
    tasks.clear();
    notes.clear();
    goals.clear();
    birthdayContacts.clear();
    customExpenseCategories.clear();
    customIncomeCategories.clear();
    await StorageService.instance.clearAll();
    notifyListeners();
  }

  // ---------------- Export ----------------
  Future<File> exportTransactionsCsv() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/transactions_export.csv');
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Amount,Payment Method,Note');
    for (final t in transactions) {
      final dateStr =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      final noteEscaped = t.note.replaceAll(',', ';');
      buffer.writeln(
          '$dateStr,${t.type.name},${t.category},${t.amount},${t.paymentMethod},$noteEscaped');
    }
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Full data backup as a JSON string (all transactions, moods, tasks,
  /// notes, goals, budgets, and settings). Can be pasted back in via
  /// [restoreFromBackup].
  String exportBackupJson() {
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'moods': moods.map((e) => e.toJson()).toList(),
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'notes': notes.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
      'customExpenseCategories': customExpenseCategories,
      'customIncomeCategories': customIncomeCategories,
      'categoryBudgets': categoryBudgets,
      'userName': userName,
      'savingsGoal': savingsGoal,
      'currency': currency,
      'birthday': birthday?.toIso8601String(),
      'birthdayContacts': birthdayContacts.map((e) => e.toJson()).toList(),
      // Deliberately excluded: aiApiKey Ã¢â‚¬â€ backups may be pasted/shared, and
      // a secret API key should never end up in that text.
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<File> exportBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/personal_tracker_backup.json');
    await file.writeAsString(exportBackupJson());
    return file;
  }

  /// Restores all data from a JSON string previously produced by
  /// [exportBackupJson]. Throws a [FormatException] if the text isn't valid
  /// backup JSON. This REPLACES all current data.
  Future<void> restoreFromBackup(String jsonText) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'That doesn\'t look like a valid backup file.');
    }

    final newTransactions = (decoded['transactions'] as List? ?? [])
        .map((e) => AppTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    final newMoods = (decoded['moods'] as List? ?? [])
        .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final newTasks = (decoded['tasks'] as List? ?? [])
        .map((e) => AppTask.fromJson(e as Map<String, dynamic>))
        .toList();
    final newNotes = (decoded['notes'] as List? ?? [])
        .map((e) => AppNote.fromJson(e as Map<String, dynamic>))
        .toList();
    final newGoals = (decoded['goals'] as List? ?? [])
        .map((e) => AppGoal.fromJson(e as Map<String, dynamic>))
        .toList();

    transactions
      ..clear()
      ..addAll(newTransactions);
    moods
      ..clear()
      ..addAll(newMoods);
    tasks
      ..clear()
      ..addAll(newTasks);
    notes
      ..clear()
      ..addAll(newNotes);
    goals
      ..clear()
      ..addAll(newGoals);
    birthdayContacts
      ..clear()
      ..addAll((decoded['birthdayContacts'] as List? ?? [])
          .map((e) => BirthdayContact.fromJson(e as Map<String, dynamic>)));

    customExpenseCategories
      ..clear()
      ..addAll(
          (decoded['customExpenseCategories'] as List? ?? []).cast<String>());
    customIncomeCategories
      ..clear()
      ..addAll(
          (decoded['customIncomeCategories'] as List? ?? []).cast<String>());

    categoryBudgets.clear();
    final budgetsMap =
        decoded['categoryBudgets'] as Map<String, dynamic>? ?? {};
    budgetsMap.forEach((k, v) => categoryBudgets[k] = (v as num).toDouble());

    userName = decoded['userName'] as String? ?? userName;
    savingsGoal = (decoded['savingsGoal'] as num?)?.toDouble() ?? savingsGoal;
    currency = decoded['currency'] as String? ?? currency;
    final birthdayStr = decoded['birthday'] as String?;
    if (birthdayStr != null) birthday = DateTime.tryParse(birthdayStr);

    await _saveTransactions();
    await _saveMoods();
    await _saveTasks();
    await _saveNotes();
    await _saveGoals();
    await StorageService.instance
        .writeString(StoreKeys.budgets, jsonEncode(categoryBudgets));
    await StorageService.instance.writeString(StoreKeys.userName, userName);
    await StorageService.instance
        .writeString(StoreKeys.savingsGoal, savingsGoal.toString());
    await StorageService.instance.writeString(StoreKeys.currency, currency);
    if (birthday != null) {
      await StorageService.instance
          .writeString(StoreKeys.birthday, birthday!.toIso8601String());
    }

    notifyListeners();
  }

  // ---------------- Monthly Review ----------------
  Map<String, dynamic> monthlyReview({DateTime? month}) {
    final m = month ?? DateTime.now();
    final monthTx = transactions
        .where((t) => t.date.year == m.year && t.date.month == m.month);
    final totalSpent = monthTx
        .where((t) => t.type == TxType.expense)
        .fold(0.0, (p, e) => p + e.amount);
    final totalIncome = monthTx
        .where((t) => t.type == TxType.income)
        .fold(0.0, (p, e) => p + e.amount);
    final moodSummary = monthMoodSummary(month: m);
    final tasksCompleted = tasks
        .where((t) =>
            t.completed &&
            t.dueDate != null &&
            t.dueDate!.year == m.year &&
            t.dueDate!.month == m.month)
        .length;
    final goalsAchieved = goals
        .where((g) =>
            g.completed &&
            g.targetDate != null &&
            g.targetDate!.year == m.year &&
            g.targetDate!.month == m.month)
        .length;

    // Most productive day = day with most completed tasks + transactions logged
    final dayCounts = <int, int>{};
    for (final t in monthTx) {
      dayCounts[t.date.day] = (dayCounts[t.date.day] ?? 0) + 1;
    }
    for (final t in tasks.where((t) =>
        t.completed &&
        t.dueDate != null &&
        t.dueDate!.year == m.year &&
        t.dueDate!.month == m.month)) {
      dayCounts[t.dueDate!.day] = (dayCounts[t.dueDate!.day] ?? 0) + 1;
    }
    int? mostProductiveDay;
    if (dayCounts.isNotEmpty) {
      mostProductiveDay =
          dayCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    return {
      'totalSpent': totalSpent,
      'totalIncome': totalIncome,
      'moodSummary': moodSummary,
      'tasksCompleted': tasksCompleted,
      'goalsAchieved': goalsAchieved,
      'mostProductiveDay': mostProductiveDay,
    };
  }

  // ---------------- Global search ----------------
  Map<String, List<dynamic>> globalSearch(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) {
      return {
        'transactions': <AppTransaction>[],
        'tasks': <AppTask>[],
        'notes': <AppNote>[],
        'goals': <AppGoal>[],
      };
    }
    return {
      'transactions': transactions
          .where((t) =>
              t.category.toLowerCase().contains(q) ||
              t.note.toLowerCase().contains(q))
          .toList(),
      'tasks': tasks.where((t) => t.title.toLowerCase().contains(q)).toList(),
      'notes': notes
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q))
          .toList(),
      'goals': goals.where((g) => g.title.toLowerCase().contains(q)).toList(),
    };
  }

  // ---------------- AI Chat ----------------
  Future<void> addChatMessage(ChatMessage message) async {
    chatMessages.add(message);
    await _saveChatHistory();
    notifyListeners();
  }

  Future<void> clearChatHistory() async {
    chatMessages.clear();
    await _saveChatHistory();
    notifyListeners();
  }

  Future<void> _saveChatHistory() => StorageService.instance.writeList(
      StoreKeys.chatHistory, chatMessages.map((e) => e.toJson()).toList());

  String newId() => _uuid.v4();
}

/// A quick snapshot of "what needs your attention right now", shown once
/// per app open as a lightweight in-app substitute for push notifications.
class LaunchDigest {
  final int overdueTaskCount;
  final int todayTaskCount;
  final bool moodLoggedToday;
  final int missedMoodDays;
  final int overBudgetCategoryCount;

  const LaunchDigest({
    required this.overdueTaskCount,
    required this.todayTaskCount,
    required this.moodLoggedToday,
    required this.missedMoodDays,
    required this.overBudgetCategoryCount,
  });

  bool get hasAnything =>
      overdueTaskCount > 0 ||
      todayTaskCount > 0 ||
      !moodLoggedToday ||
      overBudgetCategoryCount > 0;
}
