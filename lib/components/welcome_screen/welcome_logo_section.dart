import 'package:flutter/material.dart';

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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.2),
                  blurRadius: 20.0,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Hero(
              tag: 'app_logo',
              child: ClipOval(
                child: Container(
                  height: 140.0,
                  width: 140.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    'https://res.cloudinary.com/df3lhzzy7/image/upload/v1749768253/unnamed_p6zzod.jpg',
                    height: 140.0,
                    width: 140.0,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140.0,
                        width: 140.0,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.primaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140.0,
                        width: 140.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          size: 60.0,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              ),
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
                color: Colors.white, // Color is overridden by ShaderMask
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
