import 'package:flutter/material.dart';
import 'package:Tunyuke/screens/dashboard.dart';
import 'package:Tunyuke/screens/register_screen.dart';
import 'package:Tunyuke/services/auth_service.dart';

// Import your new components
import 'package:Tunyuke/components/common/app_logo_widget.dart';
import 'package:Tunyuke/components/login_screen/login_header_section.dart';
import 'package:Tunyuke/components/login_screen/login_form_fields.dart';
import 'package:Tunyuke/components/login_screen/forgot_password_link.dart';
import 'package:Tunyuke/components/login_screen/login_buttons_section.dart';

// Import the new controller
import 'package:Tunyuke/controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final LoginController _loginController; // Declare as late final

  @override
  void initState() {
    super.initState();
    // Initialize LoginController in initState
    _loginController = LoginController(
      authService: AuthService(), // Pass an instance of AuthService
      onSignInSuccess: (message) {
        print(message);
        // Now, the navigation is solely handled by the widget after success.
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        }
      },
      onSignInError: (message) {
        print("Login error: $message");
        if (mounted) {
          // <--- ADDED mounted check here
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      // onNavigateToDashboard is no longer needed as a direct controller callback
      // since navigation is handled in onSignInSuccess
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptSignIn() {
    // Renamed from _signIn to avoid confusion with controller's signIn
    if (_formKey.currentState!.validate()) {
      _loginController.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  void _handleForgotPassword() {
    print("Forgot Password pressed!");
    if (mounted) {
      // Added mounted check for this SnackBar too
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Forgot Password functionality coming soon!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 40.0),
                      Center(
                        child: AppLogoWidget(
                          imageUrl:
                              'https://res.cloudinary.com/df3lhzzy7/image/upload/v1749768253/unnamed_p6zzod.jpg',
                          size: 80.0, // Specific size for login screen
                        ),
                      ),
                      SizedBox(height: 40.0),
                      LoginHeaderSection(theme: theme),
                      SizedBox(height: 40.0),
                      LoginFormFields(
                        emailController: _emailController,
                        passwordController: _passwordController,
                      ),
                      SizedBox(height: 16.0),
                      ForgotPasswordLink(
                        onPressed: _handleForgotPassword,
                        theme: theme,
                      ),
                      SizedBox(height: 16.0),
                      LoginButtonsSection(
                        onSignInPressed: _attemptSignIn, // Call the new method
                        onSignUpPressed: _navigateToRegister,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
