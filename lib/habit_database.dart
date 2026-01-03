import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:fl_chart/fl_chart.dart'; // No longer needed for line chart
import 'habit_model.dart';
import 'notification_service.dart';

class HabitDatabase extends ChangeNotifier {
  static const String boxName = 'habitBox';
  List<Habit> habitList = [];

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(HabitAdapter());
    var box = await Hive.openBox<Habit>(boxName);
    habitList = box.values.toList();

    await NotificationService().init();

    if (habitList.isEmpty) {
      addHabit("Morning Journal", "Mindfulness", null);
      addHabit("Drink 2L Water", "Health", null);
    }
    notifyListeners();
  }

  void addHabit(String title, String category, TimeOfDay? reminder) {
    String? reminderStr = reminder != null ? "${reminder.hour}:${reminder.minute}" : null;

    final newHabit = Habit(
        title: title,
        category: category,
        completedDays: [],
        reminderTime: reminderStr,
        bestStreak: 0
    );

    var box = Hive.box<Habit>(boxName);
    box.add(newHabit);
    habitList.add(newHabit);

    if (reminder != null) {
      NotificationService().scheduleDailyNotification(
          id: newHabit.key,
          title: title,
          time: reminder
      );
    }
    notifyListeners();
  }

  void updateHabit(int index, String newTitle, TimeOfDay? newReminder) {
    var habit = habitList[index];
    habit.title = newTitle;

    if (newReminder != null) {
      habit.reminderTime = "${newReminder.hour}:${newReminder.minute}";
      NotificationService().scheduleDailyNotification(
          id: habit.key,
          title: newTitle,
          time: newReminder
      );
    } else {
      habit.reminderTime = null;
      NotificationService().cancelNotification(habit.key);
    }

    habit.save();
    notifyListeners();
  }

  void toggleHabit(Habit habit) {
    if (habit.isCompletedToday()) {
      habit.completedDays.removeWhere((date) =>
      date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day);
    } else {
      habit.completedDays.add(DateTime.now());

      int current = habit.currentStreak;
      if (current > habit.bestStreak) {
        habit.bestStreak = current;
      }
    }
    habit.save();
    notifyListeners();
  }

  void deleteHabit(int index) {
    NotificationService().cancelNotification(habitList[index].key);
    habitList[index].delete();
    habitList.removeAt(index);
    notifyListeners();
  }

  double calculateEfficiency() {
    if (habitList.isEmpty) return 0.0;
    int completedToday = habitList.where((h) => h.isCompletedToday()).length;
    return (completedToday / habitList.length);
  }

  // NEW: Prepare data for Heat Map
  Map<DateTime, int> getHeatMapDatasets() {
    Map<DateTime, int> dataset = {};

    for (var habit in habitList) {
      for (var date in habit.completedDays) {
        final normalizedDate = DateTime(date.year, date.month, date.day);

        if (dataset.containsKey(normalizedDate)) {
          dataset[normalizedDate] = dataset[normalizedDate]! + 1;
        } else {
          dataset[normalizedDate] = 1;
        }
      }
    }
    return dataset;
  }
}