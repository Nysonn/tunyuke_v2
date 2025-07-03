import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tunyuke_v2/components/welcome_screen/welcome_action_buttons.dart';
import 'package:tunyuke_v2/components/welcome_screen/welcome_feature_icons.dart';
import 'package:tunyuke_v2/components/welcome_screen/welcome_loading_section.dart';
import 'package:tunyuke_v2/components/welcome_screen/welcome_logo_section.dart';
import 'package:tunyuke_v2/dashboard.dart';
import 'package:tunyuke_v2/register_screen.dart';
import 'package:tunyuke_v2/services/auth_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool _isCheckingCredentials = true;

  final AuthService _authService = AuthService(); // Instantiate AuthService

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _slideController.forward();
    });

    // Start pulse animation for loading
    _pulseController.repeat(reverse: true);

    // Check user credentials after animations start
    _authService.authStateChanges.listen((User? user) async {
      // Make the callback async
      if (!_isCheckingCredentials)
        return; // Only process if still checking initially

      _pulseController
          .stop(); // Stop pulse animation when auth state is determined

      if (user == null) {
        // User is not logged in or token expired
        await _authService.signOut(); // Ensure SharedPreferences are cleared
        setState(() {
          _isCheckingCredentials = false;
        });
      } else {
        // User is logged in via Firebase Auth, now verify Firestore data using the outsourced method
        await _handleUserNavigation(user.uid);
      }
    });

    // Initial check in case a user is already signed in (e.g. app killed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        Future.delayed(Duration(milliseconds: 1500), () {
          // No need to call _handleUserNavigation here, the authStateChanges listener will trigger it.
          // This delay is primarily for initial animation display.
        });
      } else {
        Future.delayed(Duration(milliseconds: 2000), () {
          if (_isCheckingCredentials) {
            setState(() {
              _isCheckingCredentials = false;
            });
            _pulseController.stop();
          }
        });
      }
    });
  }

  // NEW: This method encapsulates the navigation logic based on profile existence.
  Future<void> _handleUserNavigation(String uid) async {
    try {
      final profileExists = await _authService.checkFirestoreProfileExists(uid);

      if (profileExists) {
        await Future.delayed(Duration(milliseconds: 800)); // Smooth transition
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DashboardPage()),
            (route) => false,
          );
        }
      } else {
        // Firebase Auth user exists, but no Firestore profile document
        await Future.delayed(Duration(milliseconds: 1500)); // Smooth transition
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => RegisterScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("Error during user navigation process: $e");
      setState(() {
        _isCheckingCredentials = false;
      });
      await _authService
          .signOut(); // Clear shared_preferences if an error occurs
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.05),
              Colors.white,
              theme.primaryColor.withOpacity(0.02),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: screenHeight - MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.08),

                  Expanded(
                    flex: 3,
                    child: WelcomeLogoSection(
                      fadeAnimation: _fadeAnimation,
                      theme: theme,
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _isCheckingCredentials
                          ? WelcomeLoadingSection(
                              pulseAnimation: _pulseAnimation,
                              fadeAnimation: _fadeAnimation,
                              pulseController: _pulseController,
                            )
                          : WelcomeActionButtons(theme: theme),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: WelcomeFeatureIcons(
                      fadeAnimation: _fadeAnimation,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
