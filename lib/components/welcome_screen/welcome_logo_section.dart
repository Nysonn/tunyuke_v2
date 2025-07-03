import 'package:flutter/material.dart';
import 'package:tunyuke_v2/components/common/app_logo_widget.dart';

class WelcomeLogoSection extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final ThemeData theme;

  const WelcomeLogoSection({
    Key? key,
    required this.fadeAnimation,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'app_logo',
            child: AppLogoWidget(
              imageUrl:
                  'https://res.cloudinary.com/df3lhzzy7/image/upload/v1749768253/unnamed_p6zzod.jpg',
              size: 140.0, // Specific size for welcome screen
            ),
          ),
          SizedBox(height: 30.0),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              "Tunyuke",
              style: TextStyle(
                fontSize: 42.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(height: 12.0),
          Text(
            "Welcome to your journey",
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
