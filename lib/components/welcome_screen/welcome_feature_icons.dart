import 'package:flutter/material.dart';

class WelcomeFeatureIcons extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final ThemeData theme;

  const WelcomeFeatureIcons({
    Key? key,
    required this.fadeAnimation,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureIcon(Icons.security_rounded, "Secure", theme),
              SizedBox(width: 40.0),
              _buildFeatureIcon(Icons.speed_rounded, "Fast", theme),
              SizedBox(width: 40.0),
              _buildFeatureIcon(Icons.favorite_rounded, "Reliable", theme),
            ],
          ),
          SizedBox(height: 24.0),
          // This text will always show, consider if it should be conditional
          Text(
            "Join thousands of satisfied users",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20.0),
        ),
        SizedBox(height: 8.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
