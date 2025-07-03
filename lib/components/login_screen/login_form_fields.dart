import 'package:flutter/material.dart';

class LoginFormFields extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginFormFields({
    Key? key,
    required this.emailController,
    required this.passwordController,
  }) : super(key: key);

  @override
  State<LoginFormFields> createState() => _LoginFormFieldsState();
}

class _LoginFormFieldsState extends State<LoginFormFields> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.emailController,
          decoration: InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your email.";
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return "Please enter a valid email address";
            }
            return null;
          },
        ),
        SizedBox(height: 20.0),
        TextFormField(
          controller: widget.passwordController,
          decoration: InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          obscureText: !_isPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your password.";
            }
            if (value.length < 6) {
              return "Password must be at least 6 characters";
            }
            return null;
          },
        ),
      ],
    );
  }
}
