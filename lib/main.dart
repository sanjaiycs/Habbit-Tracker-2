import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Haptics & System UI
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'habit_database.dart';
import 'habit_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Professional Status Bar Styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark icons for light mode
    statusBarBrightness: Brightness.light,    // For iOS
  ));

  final db = HabitDatabase();
  await db.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => db),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// --- THEME PROVIDER ---
class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;
  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// --- APP ENTRY POINT ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glass Habit Tracker',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F4F8), // Soft cool grey
        primaryColor: Colors.black,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark grey
        primaryColor: Colors.white,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white, brightness: Brightness.dark),
      ),
      home: const MainLayout(),
    );
  }
}

// --- MAIN LAYOUT (Tabs & Navigation) ---
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HabitDashboard(),
    const AnalyticsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Content flows behind the bottom bar
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildGlassBottomBar(isDark),
    );
  }

  // GLASSMOPRHISM NAVIGATION BAR
  Widget _buildGlassBottomBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 0, isDark),
              _buildNavItem(Icons.bar_chart_rounded, 1, isDark),
              _buildNavItem(Icons.settings_outlined, 2, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool isDark) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          HapticFeedback.lightImpact(); // Subtle vibration
          setState(() => _selectedIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white54 : Colors.black45),
          size: 24,
        ),
      ),
    );
  }
}

// --- PAGE 1: DASHBOARD ---
class HabitDashboard extends StatefulWidget {
  const HabitDashboard({super.key});

  @override
  State<HabitDashboard> createState() => _HabitDashboardState();
}

class _HabitDashboardState extends State<HabitDashboard> {
  TimeOfDay? selectedTime;

  // Custom Styled Dialog for Add/Edit
  void _showHabitDialog(BuildContext context, {Habit? habit, int? index}) async {
    final controller = TextEditingController(text: habit?.title ?? "");
    selectedTime = habit?.getReminderTime();
    bool isEditing = habit != null;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? "Edit Habit" : "New Habit",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: "What do you want to do?",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_outlined, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime == null ? "Set Reminder" : selectedTime!.format(context),
                              style: TextStyle(
                                color: selectedTime == null ? Colors.grey[400] : (isDark ? Colors.white : Colors.black),
                                fontWeight: selectedTime == null ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (selectedTime != null)
                              GestureDetector(
                                  onTap: () => setDialogState(() => selectedTime = null),
                                  child: Icon(Icons.close, size: 18, color: Colors.grey[500])
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (controller.text.isNotEmpty) {
                              HapticFeedback.mediumImpact();
                              if (isEditing) {
                                Provider.of<HabitDatabase>(context, listen: false)
                                    .updateHabit(index!, controller.text, selectedTime);
                              } else {
                                Provider.of<HabitDatabase>(context, listen: false)
                                    .addHabit(controller.text, "General", selectedTime);
                              }
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(isEditing ? "Save" : "Create"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<HabitDatabase>(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar FIXED: Title and Icon aligned at top
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            titleSpacing: 20, // Match body padding
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "My Habits",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 28, // Header size
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showHabitDialog(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                    ),
                    child: Icon(
                        Icons.add,
                        color: isDark ? Colors.white : Colors.black,
                        size: 24
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress Card - BIGGER SIZE, THINNER STROKE
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
                    ]
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Daily Goal", style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text("${(db.calculateEfficiency() * 100).toInt()}% Done",
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0)),
                      ],
                    ),
                    const Spacer(),
                    // CHANGED: Size 100, Stroke 8 (Bigger but elegant)
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background Ring
                          CircularProgressIndicator(
                            value: 1.0,
                            backgroundColor: Colors.transparent,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            strokeWidth: 5, // Thinner stroke
                          ),
                          // Progress Ring
                          CircularProgressIndicator(
                            value: db.calculateEfficiency(),
                            backgroundColor: Colors.transparent,
                            color: isDark ? Colors.white : Colors.black,
                            strokeCap: StrokeCap.round,
                            strokeWidth: 5, // Thinner stroke
                          ),
                          Text(
                            "${db.habitList.where((h)=>h.isCompletedToday()).length}/${db.habitList.length}",
                            style: TextStyle(
                                fontSize: 16, // Larger font
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Habit List or Empty State
          if (db.habitList.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text("No habits yet", style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text("Tap the + button to start your journey", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final habit = db.habitList[index];
                    return _buildHabitTile(habit, index, db, isDark, context);
                  },
                  childCount: db.habitList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitTile(Habit habit, int index, HabitDatabase db, bool isDark, BuildContext context) {
    Color streakColor = Colors.grey;
    if (habit.currentStreak >= 3) streakColor = Colors.orangeAccent;
    if (habit.currentStreak >= 7) streakColor = Colors.blueAccent;

    return Dismissible(
      key: Key(habit.key.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        db.deleteHabit(index);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Habit deleted"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              width: 200,
            )
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.selectionClick();
          _showHabitDialog(context, habit: habit, index: index);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  db.toggleHabit(habit);

                  if (db.calculateEfficiency() == 1.0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("🔥 All habits completed! Great job!"),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        )
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutBack,
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: habit.isCompletedToday()
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white10 : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(16),
                    border: habit.isCompletedToday()
                        ? null
                        : Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: habit.isCompletedToday()
                      ? Icon(Icons.check, color: isDark ? Colors.black : Colors.white, size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: habit.isCompletedToday() ? TextDecoration.lineThrough : null,
                        color: habit.isCompletedToday()
                            ? Colors.grey
                            : (isDark ? Colors.white : const Color(0xFF2D3142)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (habit.reminderTime != null)
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            habit.getReminderTime()!.format(context),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          )
                        ],
                      )
                  ],
                ),
              ),
              if (habit.currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: streakColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: streakColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "${habit.currentStreak}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: streakColor, fontSize: 14),
                      )
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

// --- PAGE 2: ANALYTICS ---
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final db = Provider.of<HabitDatabase>(context);
    final heatMapData = db.getHeatMapDatasets();

    return Scaffold(
      appBar: AppBar(
        title: Text("Analytics", style: TextStyle(fontWeight: FontWeight.bold, color: isDark? Colors.white:Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          // 1. HEATMAP
          Container(
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 5))]
            ),
            child: MonthlySummary(
              datasets: heatMapData,
              startDate: DateTime.now().toString(),
              totalHabits: db.habitList.length,
            ),
          ),
          const SizedBox(height: 24),
          const Text("Statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // 2. STATS GRID (FIXED: Ratio 1.1 prevents overflow)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: [
              _buildStatCard("Total Habits", "${db.habitList.length}", Icons.list_alt_rounded, Colors.purpleAccent, isDark),
              _buildStatCard("Completed", "${db.habitList.where((h)=>h.isCompletedToday()).length}", Icons.check_circle_outline_rounded, Colors.greenAccent, isDark),
              _buildStatCard("Best Streak", "${_calculateBestStreak(db)}", Icons.emoji_events_outlined, Colors.orangeAccent, isDark),
              _buildStatCard("Efficiency", "${(db.calculateEfficiency()*100).toInt()}%", Icons.pie_chart_outline_rounded, Colors.blueAccent, isDark),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateBestStreak(HabitDatabase db) {
    if (db.habitList.isEmpty) return 0;
    int max = 0;
    for (var h in db.habitList) {
      int best = h.bestStreak > h.currentStreak ? h.bestStreak : h.currentStreak;
      if (best > max) max = best;
    }
    return max;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}

// --- PAGE 3: SETTINGS ---
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, color: isDark?Colors.white:Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          Container(
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w600)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.dark_mode_outlined, color: Colors.purple),
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    themeProvider.toggleTheme(val);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.purple,
                ),
                Divider(color: Colors.grey.withOpacity(0.1), height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_outlined, color: Colors.blue),
                  ),
                  title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Manage reminders", style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.grey),
              ),
              title: const Text("About", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("v1.0.0", style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                showAboutDialog(context: context, applicationName: "Glass Habit Tracker", applicationVersion: "1.0.0");
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- HEATMAP WIDGET ---
class MonthlySummary extends StatefulWidget {
  final Map<DateTime, int>? datasets;
  final String startDate;
  final int totalHabits;

  const MonthlySummary({
    super.key,
    required this.datasets,
    required this.startDate,
    required this.totalHabits,
  });

  @override
  State<MonthlySummary> createState() => _MonthlySummaryState();
}

class _MonthlySummaryState extends State<MonthlySummary> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Map<DateTime, int> data = {};
    if (widget.datasets != null) {
      widget.datasets!.forEach((date, value) {
        final normalized = DateTime(date.year, date.month, date.day);
        data[normalized] = value;
      });
    }

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final int weekdayOfFirst = firstDayOfMonth.weekday;
    final int leadingEmptyCells = weekdayOfFirst % 7;

    final int totalCells = leadingEmptyCells + daysInMonth;
    final int trailingEmptyCells = (7 - (totalCells % 7)) % 7;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Text(
                  "${_monthName(_currentMonth.month)} ${_currentMonth.year}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToPreviousMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToNextMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
            child: Row(
              children: const [
                _WeekdayLabel("S"),
                _WeekdayLabel("M"),
                _WeekdayLabel("T"),
                _WeekdayLabel("W"),
                _WeekdayLabel("T"),
                _WeekdayLabel("F"),
                _WeekdayLabel("S"),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(4.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: leadingEmptyCells + daysInMonth + trailingEmptyCells,
              itemBuilder: (context, index) {
                if (index < leadingEmptyCells ||
                    index >= leadingEmptyCells + daysInMonth) {
                  return const SizedBox.shrink();
                }

                final day = index - leadingEmptyCells + 1;
                final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                final key = DateTime(date.year, date.month, date.day);
                final int value = data[key] ?? 0;

                return _DayCell(
                    day: day,
                    value: value,
                    totalHabits: widget.totalHabits
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return names[m - 1];
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[500]
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int value;
  final int totalHabits;

  const _DayCell({
    required this.day,
    required this.value,
    required this.totalHabits
  });

  Color _colorForValue(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (value <= 0 || totalHabits == 0) {
      return isDark ? Colors.white10 : Colors.grey[200]!;
    }

    double percentage = (value / totalHabits).clamp(0.0, 1.0);
    double opacity = (percentage < 0.2) ? 0.2 : percentage;

    return const Color(0xFF2E7D32).withOpacity(opacity);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForValue(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Day $day: $value / $totalHabits completed"),
            duration: const Duration(milliseconds: 600),
            behavior: SnackBarBehavior.floating,
            width: 250,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          "$day",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            color: value > 0 ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
    );
  }
}