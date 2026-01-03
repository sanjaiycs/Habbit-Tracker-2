import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String category;

  @HiveField(2)
  List<DateTime> completedDays;

  // New Fields
  @HiveField(3)
  String? reminderTime; // Stored as "HH:MM" string

  @HiveField(4)
  int bestStreak;

  Habit({
    required this.title,
    required this.category,
    required this.completedDays,
    this.reminderTime,
    this.bestStreak = 0,
  });

  bool isCompletedOnDate(DateTime date) {
    return completedDays.any((d) =>
    d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool isCompletedToday() {
    return isCompletedOnDate(DateTime.now());
  }

  int get currentStreak {
    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = isCompletedToday() ? now : now.subtract(const Duration(days: 1));

    while (true) {
      if (isCompletedOnDate(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // Helper to get TimeOfDay from stored string
  TimeOfDay? getReminderTime() {
    if (reminderTime == null) return null;
    final parts = reminderTime!.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}