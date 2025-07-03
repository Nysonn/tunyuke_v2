import 'package:flutter/material.dart';

class ForgotPasswordLink extends StatelessWidget {
  final VoidCallback onPressed;
  final ThemeData theme;

  const ForgotPasswordLink({
    Key? key,
    required this.onPressed,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          "Forgot Password?",
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }
}
