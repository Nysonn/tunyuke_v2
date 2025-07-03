import 'package:flutter/material.dart';

class RegisterButtonsSection extends StatelessWidget {
  final VoidCallback onSignUpPressed;
  final VoidCallback onSignInPressed;
  final ThemeData theme;

  const RegisterButtonsSection({
    Key? key,
    required this.onSignUpPressed,
    required this.onSignInPressed,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.0),
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
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
            onPressed: onSignUpPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.0),
              ),
            ),
            child: Text(
              "Sign Up",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        SizedBox(height: 32.0),
        TextButton(
          onPressed: onSignInPressed,
          child: Text(
            "Already have an account? Sign In",
            style: TextStyle(
              fontSize: 16.0,
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
