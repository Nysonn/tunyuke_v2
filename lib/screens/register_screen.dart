import 'package:flutter/material.dart';
import 'package:tunyuke_v2/screens/login_screen.dart';
import 'package:tunyuke_v2/services/auth_service.dart'; // Import AuthService

// Import your new components
import 'package:tunyuke_v2/components/common/app_logo_widget.dart';
import 'package:tunyuke_v2/components/register_screen/register_header_section.dart';
import 'package:tunyuke_v2/components/register_screen/register_form_fields.dart';
import 'package:tunyuke_v2/components/register_screen/register_buttons_section.dart';

// Import the new controller
import 'package:tunyuke_v2/controllers/register_controller.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final RegisterController _registerController; // Declare as late final

  @override
  void initState() {
    super.initState();
    // Initialize RegisterController in initState
    _registerController = RegisterController(
      authService: AuthService(), // Pass an instance of AuthService
      onSignUpSuccess: (message) {
        print(message);
        // No SnackBar on success, just navigate
      },
      onSignUpError: (message) {
        print("Sign-up error: $message");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      onNavigateToLogin: () {
        if (mounted) {
          // Ensure widget is still in the tree before navigating
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptSignUp() {
    // Renamed from _signUp to avoid confusion with controller's signUp
    if (_formKey.currentState!.validate()) {
      _registerController.signUp(
        email: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
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
                          size: 80.0, // Specific size for register screen
                        ),
                      ),
                      SizedBox(height: 40.0),
                      RegisterHeaderSection(theme: theme),
                      SizedBox(height: 40.0),
                      RegisterFormFields(
                        emailController: _emailController,
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                      ),
                      SizedBox(height: 32.0),
                      RegisterButtonsSection(
                        onSignUpPressed: _attemptSignUp, // Call the new method
                        onSignInPressed: _navigateToLogin,
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
