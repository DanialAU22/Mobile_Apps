import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_helper.dart';
import 'providers/exam_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/study_session_provider.dart';
import 'providers/subject_provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.init();
  await NotificationService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final hour = prefs.getInt('reminder_hour') ?? 18;
  final minute = prefs.getInt('reminder_minute') ?? 0;
  await NotificationService.instance.scheduleDailyStudyReminder(
    hour: hour,
    minute: minute,
  );

  runApp(const StudyPlannerApp());
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorSchemeSeed = Colors.teal;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final p = SettingsProvider();
          p.load();
          return p;
        }),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => StudySessionProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Study Deadline & Exam Planner',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: colorSchemeSeed,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: colorSchemeSeed,
          brightness: Brightness.dark,
        ),
        home: const HomeScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
        ],
          );
        },
      ),
    );
  }
}

