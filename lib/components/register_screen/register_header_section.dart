import 'package:flutter/material.dart';

class RegisterHeaderSection extends StatelessWidget {
  final ThemeData theme;

  const RegisterHeaderSection({Key? key, required this.theme})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
      ).createShader(bounds),
      child: Text(
        "Sign Up",
        style: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.w700,
          color: Colors.white, // Color is overridden by ShaderMask
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
