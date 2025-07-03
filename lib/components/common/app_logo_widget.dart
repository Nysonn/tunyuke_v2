import 'package:flutter/material.dart';

class AppLogoWidget extends StatelessWidget {
  final double size;
  final String imageUrl;

  const AppLogoWidget({
    Key? key,
    this.size = 80.0, // Default size
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.15),
            blurRadius: 10.0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image_not_supported,
                  size: size * 0.5, // Icon size relative to logo size
                  color: Colors.grey[400],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
