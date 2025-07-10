import 'package:flutter/material.dart';
import 'package:Tunyuke/screens/login_screen.dart';
import 'package:Tunyuke/services/auth_service.dart';

import 'package:Tunyuke/components/common/app_logo_widget.dart';
import 'package:Tunyuke/components/register_screen/register_header_section.dart';
import 'package:Tunyuke/components/register_screen/register_form_fields.dart';
import 'package:Tunyuke/components/register_screen/register_buttons_section.dart';

import 'package:Tunyuke/controllers/register_controller.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptSignUp(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      Provider.of<RegisterController>(context, listen: false).signUp(
        email: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<RegisterController>(
      builder: (context, registerController, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (registerController.signUpSuccess) {
            registerController.reset();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          } else if (registerController.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(registerController.errorMessage!)),
            );
            registerController.reset();
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
                              size: 80.0,
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
                            onSignUpPressed: () => _attemptSignUp(context),
                            onSignInPressed: () => _navigateToLogin(context),
                            theme: theme,
                          ),
                          if (registerController.isLoading)
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
