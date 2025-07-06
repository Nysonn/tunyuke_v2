import 'package:Tunyuke/screens/dashboard.dart';
import 'package:Tunyuke/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:Tunyuke/controllers/dashboard_controller.dart';
import 'package:Tunyuke/screens/login_screen.dart';
import 'package:Tunyuke/screens/to_campus_screen.dart';
import 'package:Tunyuke/screens/from_campus_screen.dart';
import 'package:Tunyuke/screens/schedule_team_ride_screen.dart';
import 'package:Tunyuke/screens/onboard_scheduled_ride_screen.dart';
import 'package:Tunyuke/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      // Wrap MyApp with ChangeNotifierProvider
      create: (context) => DashboardController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tunyuke',
      theme: ThemeData(primarySwatch: Colors.purple),
      // Define your named routes here
      routes: {
        '/': (context) => const WelcomePage(),
        '/welcome': (context) => const WelcomePage(),
        '/dashboard': (context) => DashboardPage(),
        '/login': (context) => LoginScreen(),
        '/to_campus': (context) => const ToCampusScreen(),
        '/from_campus': (context) => const FromCampusScreen(),
        '/schedule_team_ride': (context) => const ScheduleTeamRideScreen(),
        '/onboard_scheduled_ride': (context) =>
            const OnboardScheduledRideScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      initialRoute: '/welcome', // Start on the WelcomePage
      debugShowCheckedModeBanner: false,
    );
  }
}
