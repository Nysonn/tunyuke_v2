import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String greeting;
  final String userName;
  final ThemeData theme;

  const DashboardAppBar({
    super.key,
    required this.greeting,
    required this.userName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: theme.primaryColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(55),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_car_rounded,
            color: theme.primaryColor,
            size: 24,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$greeting, ",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: userName,
                  style: TextStyle(
                    fontSize: 19.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                // TextSpan(text: " ✨", style: TextStyle(fontSize: 8.0)),
              ],
            ),
          ),
          Text(
            "Ready for your journey?",
            style: TextStyle(fontSize: 12.0, color: Colors.white),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // Handle notifications
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight); // Standard AppBar height
}
