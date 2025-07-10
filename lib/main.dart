import 'package:Tunyuke/screens/dashboard.dart';
import 'package:Tunyuke/screens/notifications.dart';
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
import 'package:Tunyuke/controllers/to_campus_controller.dart';
import 'package:Tunyuke/controllers/schedule_team_ride_controller.dart';
import 'package:Tunyuke/controllers/waiting_time_controller.dart';
import 'package:Tunyuke/controllers/onboarding_controller.dart';
import 'package:Tunyuke/controllers/rides_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Tunyuke/controllers/login_controller.dart';
import 'package:Tunyuke/controllers/register_controller.dart';
import 'package:Tunyuke/controllers/profile_screen_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Function to fetch and log FCM token
  void fetchAndLogFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print('🔥 FCM registration token: $token');
    // You can also store this locally or send it directly to your backend here
  }

  // Fetch and log the token
  fetchAndLogFCMToken();

  runApp(
    MultiProvider(
      providers: [
        // Wrap MyApp with MultiProvider to provide multiple controllers
        ChangeNotifierProvider(create: (context) => DashboardController()),
        ChangeNotifierProvider(create: (context) => ToCampusController()),
        ChangeNotifierProvider(
          create: (context) => ScheduleTeamRideController(),
        ),
        ChangeNotifierProvider(create: (context) => WaitingTimeController()),
        ChangeNotifierProvider(create: (context) => OnboardingController()),
        ChangeNotifierProvider(create: (context) => RidesController()),
        ChangeNotifierProvider(create: (context) => LoginController()),
        ChangeNotifierProvider(create: (context) => RegisterController()),
        ChangeNotifierProvider(create: (context) => ProfileScreenController()),
      ],
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
      routes: {
        '/': (context) => const WelcomePage(),
        '/welcome': (context) => const WelcomePage(),
        '/dashboard': (context) => DashboardPage(),
        '/notifications': (context) => Notifications(),
        '/login': (context) => LoginScreen(),
        '/to_campus': (context) => ToCampusPage(),
        '/from_campus': (context) => const FromCampusPage(),
        '/schedule_team_ride': (context) => const ScheduleTeamRideScreen(),
        '/onboard_scheduled_ride': (context) =>
            const OnboardScheduledRideScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      initialRoute: '/welcome',
      debugShowCheckedModeBanner: false,
    );
  }
}
