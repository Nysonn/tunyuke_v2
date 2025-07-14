import 'package:flutter/material.dart';

class LoginHeaderSection extends StatelessWidget {
  final ThemeData theme;

  const LoginHeaderSection({Key? key, required this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          ).createShader(bounds),
          child: Text(
            "Welcome Back",
            style: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.w700,
              color: Colors.white, // Color is overridden by ShaderMask
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          "Sign in to continue",
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
