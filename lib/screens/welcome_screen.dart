import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Tunyuke/components/welcome_screen/welcome_action_buttons.dart';
import 'package:Tunyuke/components/welcome_screen/welcome_feature_icons.dart';
import 'package:Tunyuke/components/welcome_screen/welcome_loading_section.dart';
import 'package:Tunyuke/components/welcome_screen/welcome_logo_section.dart';
import 'package:Tunyuke/screens/dashboard.dart';
import 'package:Tunyuke/screens/register_screen.dart';
import 'package:Tunyuke/services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check authentication after the build phase is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationState();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
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
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) _slideController.forward();
    });
    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkAuthenticationState() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      print("🔍 Checking authentication state...");

      // Check SharedPreferences first
      final isLoggedIn = await authService.isLoggedIn();
      final savedUid = await authService.getCurrentUserUid();
      final currentUser = FirebaseAuth.instance.currentUser;

      print(
        "📱 SharedPreferences - isLoggedIn: $isLoggedIn, savedUid: $savedUid",
      );
      print("🔥 Firebase Auth - currentUser: ${currentUser?.uid}");

      if (isLoggedIn && savedUid != null) {
        // User should be logged in according to SharedPreferences
        if (currentUser != null && currentUser.uid == savedUid) {
          print("✅ Valid authentication state - navigating to app");
          await _handleUserNavigation(currentUser.uid, authService);
        } else if (currentUser == null) {
          print(
            "⚠️ SharedPreferences indicates login but no Firebase user - attempting silent refresh",
          );
          // Try to restore Firebase session
          await FirebaseAuth.instance.authStateChanges().first;
          final refreshedUser = FirebaseAuth.instance.currentUser;

          if (refreshedUser != null && refreshedUser.uid == savedUid) {
            print("✅ Firebase session restored - navigating to app");
            await _handleUserNavigation(refreshedUser.uid, authService);
          } else {
            print(
              "❌ Could not restore Firebase session - clearing login state",
            );
            await _clearInvalidSession(authService);
          }
        } else {
          print("❌ UID mismatch - clearing invalid session");
          await _clearInvalidSession(authService);
        }
      } else if (currentUser != null) {
        print("⚠️ Firebase user exists but no SharedPreferences login state");
        // Firebase user exists but SharedPreferences doesn't indicate login
        // This could happen if the app was uninstalled/reinstalled
        await _handleUserNavigation(currentUser.uid, authService);
      } else {
        print("ℹ️ No authentication found - showing welcome screen");
        await _showWelcomeScreen();
      }
    } catch (e) {
      print("❌ Error checking authentication state: $e");
      await _showWelcomeScreen();
    }
  }

  Future<void> _handleUserNavigation(
    String uid,
    AuthService authService,
  ) async {
    try {
      print("🔍 Checking Firestore profile for UID: $uid");

      // Verify the user's authentication is still valid
      final isAuthValid = await authService.isAuthenticationValid();
      if (!isAuthValid) {
        print("❌ Authentication is no longer valid");
        await _clearInvalidSession(authService);
        return;
      }

      final profileExists = await authService.checkFirestoreProfileExists(uid);
      print("📄 Firestore profile exists: $profileExists");

      if (profileExists) {
        // Update login state to ensure consistency
        await authService.saveLoginState(true, uid);

        print("🏠 Navigating to Dashboard");
        await Future.delayed(Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DashboardPage()),
            (route) => false,
          );
        }
      } else {
        print("📝 Profile doesn't exist - navigating to registration");
        await Future.delayed(Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => RegisterScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("❌ Error during user navigation: $e");
      await _clearInvalidSession(authService);
    }
  }

  Future<void> _clearInvalidSession(AuthService authService) async {
    try {
      print("🧹 Clearing invalid session");
      await authService.signOut();
      await _showWelcomeScreen();
    } catch (e) {
      print("❌ Error clearing session: $e");
      await _showWelcomeScreen();
    }
  }

  Future<void> _showWelcomeScreen() async {
    if (mounted) {
      setState(() {
        _isCheckingCredentials = false;
      });
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
