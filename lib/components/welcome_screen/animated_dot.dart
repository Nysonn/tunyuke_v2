import 'package:flutter/material.dart';

class AnimatedDot extends StatelessWidget {
  final AnimationController pulseController;
  final int index;
  final Color dotColor;

  const AnimatedDot({
    Key? key,
    required this.pulseController,
    required this.index,
    required this.dotColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        double delay = index * 0.3;
        double animationValue = (pulseController.value + delay) % 1.0;
        double opacity = (0.3 + (0.7 * (1.0 - animationValue.abs()))).clamp(
          0.0,
          1.0,
        );

        return Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: dotColor.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
