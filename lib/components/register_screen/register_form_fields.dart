import 'package:flutter/material.dart';

class RegisterFormFields extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const RegisterFormFields({
    Key? key,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
  }) : super(key: key);

  @override
  State<RegisterFormFields> createState() => _RegisterFormFieldsState();
}

class _RegisterFormFieldsState extends State<RegisterFormFields> {
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
            if (!RegExp(
              r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
            ).hasMatch(value)) {
              return "Please enter a valid email address.";
            }
            return null;
          },
        ),
        SizedBox(height: 20.0),
        TextFormField(
          controller: widget.usernameController,
          decoration: InputDecoration(
            labelText: "Username",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your username.";
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
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your password.";
            }
            if (value.length < 6) {
              return "Password must be at least 6 characters long.";
            }
            return null;
          },
        ),
      ],
    );
  }
}
