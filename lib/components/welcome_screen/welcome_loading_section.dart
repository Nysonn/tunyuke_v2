import 'package:flutter/material.dart';
import 'package:Tunyuke/components/welcome_screen/animated_dot.dart';

class WelcomeLoadingSection extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final Animation<double> fadeAnimation;
  final AnimationController pulseController; // Pass the controller for dots
  // Removed _statusMessage from here as it's not present in your latest WelcomePage
  // If you want status messages, you need to pass it from WelcomePage

  const WelcomeLoadingSection({
    Key? key,
    required this.pulseAnimation,
    required this.fadeAnimation,
    required this.pulseController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme here

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: pulseAnimation,
          child: Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 20.0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.shield_rounded,
                size: 40.0,
                color: theme.primaryColor,
              ),
            ),
          ),
        ),
        SizedBox(height: 32.0),
        Container(
          width: 200.0,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Container(
                height: 6.0,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3.0),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.1),
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3.0),
                  child: AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: null,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                        backgroundColor: Colors.transparent,
                        minHeight: 6.0,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              FadeTransition(
                opacity: fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDot(
                      pulseController: pulseController,
                      index: 0,
                      dotColor: theme.primaryColor,
                    ),
                    SizedBox(width: 8.0),
                    AnimatedDot(
                      pulseController: pulseController,
                      index: 1,
                      dotColor: theme.primaryColor,
                    ),
                    SizedBox(width: 8.0),
                    AnimatedDot(
                      pulseController: pulseController,
                      index: 2,
                      dotColor: theme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
