// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tunyuke_v2/dashboard.dart';
import 'package:tunyuke_v2/login_screen.dart';
import 'package:tunyuke_v2/register_screen.dart';
import 'package:tunyuke_v2/services/auth_service.dart';

class WelcomePage extends StatefulWidget {
  @override
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
    // Using an auth state listener is more robust than a fixed delay
    _authService.authStateChanges.listen((User? user) {
      if (!_isCheckingCredentials)
        return; // Only process if still checking initially

      // Stop pulse animation and then proceed
      _pulseController.stop();

      if (user == null) {
        // User is not logged in or token expired
        _authService.signOut(); // Ensure SharedPreferences are cleared
        setState(() {
          _isCheckingCredentials = false;
        });
      } else {
        // User is logged in via Firebase Auth, now verify Firestore data
        _verifyFirestoreProfile(user.uid);
      }
    });

    // Initial check in case a user is already signed in (e.g. app killed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        Future.delayed(Duration(milliseconds: 1500), () {});
      } else {
        // If no user found immediately, ensure we eventually show action buttons
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

  Future<void> _verifyFirestoreProfile(String uid) async {
    try {
      // Keep the loading state active during verification
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        // Add a small delay for smooth user experience
        await Future.delayed(Duration(milliseconds: 800));

        if (mounted) {
          // Check if the widget is still mounted before navigating
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DashboardPage()),
            (route) => false,
          );
        }
      } else {
        // Firebase Auth user exists, but no Firestore profile document
        // This implies incomplete registration or deleted profile.
        await Future.delayed(Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => RegisterScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("Error verifying Firestore profile: $e");
      setState(() {
        _isCheckingCredentials = false;
      });
      _authService.signOut(); // Clear shared_preferences if an error occurs
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
    final screenWidth = MediaQuery.of(context).size.width;

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
                  // Top spacer
                  SizedBox(height: screenHeight * 0.08),

                  // Logo and branding section
                  Expanded(
                    flex: 3,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Enhanced logo with shadow and animation
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withOpacity(0.2),
                                  blurRadius: 20.0,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'app_logo',
                              child: ClipOval(
                                child: Container(
                                  height: 140.0,
                                  width: 140.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    'https://res.cloudinary.com/df3lhzzy7/image/upload/v1749768253/unnamed_p6zzod.jpg',
                                    height: 140.0,
                                    width: 140.0,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 140.0,
                                        width: 140.0,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 140.0,
                                        width: 140.0,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 60.0,
                                          color: Colors.grey[400],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 30.0),

                          // Enhanced app name with gradient text
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                theme.primaryColor,
                                theme.primaryColor.withOpacity(0.8),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              "Tunyuke",
                              style: TextStyle(
                                fontSize: 42.0,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          SizedBox(height: 12.0),

                          // Enhanced subtitle
                          Text(
                            "Welcome to your journey",
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons or loading section with enhanced styling
                  Expanded(
                    flex: 2,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _isCheckingCredentials
                          ? _buildEnhancedLoadingSection()
                          : _buildEnhancedActionButtons(theme),
                    ),
                  ),

                  // Enhanced bottom section
                  Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFeatureIcon(
                                Icons.security_rounded,
                                "Secure",
                              ),
                              SizedBox(width: 40.0),
                              _buildFeatureIcon(Icons.speed_rounded, "Fast"),
                              SizedBox(width: 40.0),
                              _buildFeatureIcon(
                                Icons.favorite_rounded,
                                "Reliable",
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Text(
                            _isCheckingCredentials
                                ? "Securing your experience"
                                : "Join thousands of satisfied users",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildEnhancedLoadingSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Enhanced loading icon with pulse animation
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 20.0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.shield_rounded,
                size: 40.0,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),

        SizedBox(height: 32.0),

        // Enhanced progress bar with container styling
        Container(
          width: 200.0,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Progress bar with custom styling
              Container(
                height: 6.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3.0),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3.0),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: null, // Indeterminate progress
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        backgroundColor: Colors.transparent,
                        minHeight: 6.0,
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 16.0),

              // Animated dots indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedDot(0),
                    SizedBox(width: 8.0),
                    _buildAnimatedDot(1),
                    SizedBox(width: 8.0),
                    _buildAnimatedDot(2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double delay = index * 0.3;
        double animationValue = (_pulseController.value + delay) % 1.0;
        double opacity = (0.3 + (0.7 * (1.0 - animationValue.abs()))).clamp(
          0.0,
          1.0,
        );

        return Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildEnhancedActionButtons(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced Get Started button
          Container(
            width: double.infinity,
            height: 56.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 15.0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20.0),

          // Enhanced divider with "or" text
          Row(
            children: [
              Expanded(child: Container(height: 1.0, color: Colors.grey[300])),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "or",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1.0, color: Colors.grey[300])),
            ],
          ),

          SizedBox(height: 20.0),

          // Enhanced Sign In button with outline style
          Container(
            width: double.infinity,
            height: 56.0,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.primaryColor, width: 2.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.0),
                ),
              ),
              child: Text(
                "Sign In",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20.0),
        ),
        SizedBox(height: 8.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
