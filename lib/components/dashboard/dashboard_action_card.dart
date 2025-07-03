import 'package:flutter/material.dart';

class DashboardActionCard extends StatelessWidget {
  final Animation<double> animation;
  final IconData icon;
  final String title;
  final String subtitle;
  final String info;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  const DashboardActionCard({
    Key? key,
    required this.animation,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.info,
    required this.onTap,
    required this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Clamp the animation value to ensure it stays within 0.0 and 1.0
        final animationValue = animation.value.clamp(0.0, 1.0);

        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.15),
                    blurRadius: 12.0,
                    offset: Offset(0, 6),
                    spreadRadius: 1.0,
                  ),
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8.0,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: gradientColors[0].withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20.0),
                  splashColor: gradientColors[0].withOpacity(0.1),
                  highlightColor: gradientColors[0].withOpacity(0.05),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with gradient background
                        Container(
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withOpacity(0.25),
                                blurRadius: 8.0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 24.0, color: Colors.white),
                        ),
                        SizedBox(height: 12.0),

                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.0),

                        // Subtitle
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.0),

                        // Info badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: gradientColors[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            info,
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w500,
                              color: gradientColors[0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
