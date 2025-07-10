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
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptSignIn(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      Provider.of<LoginController>(context, listen: false).signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  void _handleForgotPassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forgot Password functionality coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<LoginController>(
      builder: (context, loginController, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (loginController.loginSuccess) {
            loginController.reset();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          } else if (loginController.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loginController.errorMessage!)),
            );
            loginController.reset();
          }
        });
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
                            onPressed: () => _handleForgotPassword(context),
                            theme: theme,
                          ),
                          SizedBox(height: 16.0),
                          LoginButtonsSection(
                            onSignInPressed: () => _attemptSignIn(context),
                            onSignUpPressed: () => _navigateToRegister(context),
                            theme: theme,
                          ),
                          if (loginController.isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: Center(child: CircularProgressIndicator()),
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
      },
    );
  }
}
