import 'package:flutter/material.dart';

class FallbackScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final bool showRetryButton;
  final Color? primaryColor;
  final Widget? customAction;

  const FallbackScreen({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryButtonText = "Try Again",
    this.showRetryButton = true,
    this.primaryColor,
    this.customAction,
  });

  // Predefined fallback types for common scenarios
  static Widget noConnection({
    VoidCallback? onRetry,
    String? retryButtonText,
    Color? primaryColor,
  }) {
    return FallbackScreen(
      title: "No Connection",
      message: "Please check your internet connection and try again.",
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
      primaryColor: primaryColor,
    );
  }

  static Widget serverError({
    VoidCallback? onRetry,
    String? retryButtonText,
    Color? primaryColor,
  }) {
    return FallbackScreen(
      title: "Server Error",
      message: "Something went wrong on our end. Please try again in a moment.",
      icon: Icons.error_outline_rounded,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
      primaryColor: primaryColor,
    );
  }

  static Widget noData({
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryButtonText,
    Color? primaryColor,
  }) {
    return FallbackScreen(
      title: title ?? "No Data Available",
      message: message ?? "There's nothing to show right now.",
      icon: Icons.inbox_rounded,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
      primaryColor: primaryColor,
    );
  }

  static Widget unauthorized({
    VoidCallback? onRetry,
    String? retryButtonText,
    Color? primaryColor,
  }) {
    return FallbackScreen(
      title: "Access Denied",
      message:
          "You don't have permission to view this content. Please log in again.",
      icon: Icons.lock_outline_rounded,
      onRetry: onRetry,
      retryButtonText: retryButtonText ?? "Login Again",
      primaryColor: primaryColor,
    );
  }

  static Widget maintenance({
    VoidCallback? onRetry,
    String? retryButtonText,
    Color? primaryColor,
  }) {
    return FallbackScreen(
      title: "Under Maintenance",
      message:
          "We're currently updating our services. Please check back later.",
      icon: Icons.build_rounded,
      onRetry: onRetry,
      retryButtonText: retryButtonText ?? "Check Again",
      primaryColor: primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = primaryColor ?? theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: effectivePrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Icons.error_outline_rounded,
                    size: 64,
                    color: effectivePrimaryColor.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  title ?? "Something went wrong",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Message
                Text(
                  message ??
                      "We encountered an unexpected error. Please try again.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Action buttons
                if (customAction != null)
                  customAction!
                else if (showRetryButton && onRetry != null)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            retryButtonText ??
                                "Try Again", // Fixed: Use null-aware operator
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: effectivePrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Go back button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Go Back",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (showRetryButton)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Go Back",
                      style: TextStyle(
                        fontSize: 16,
                        color: effectivePrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for inline error states (not full screen)
class FallbackWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final bool showRetryButton;
  final Color? primaryColor;
  final double? height;

  const FallbackWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryButtonText = "Try Again",
    this.showRetryButton = true,
    this.primaryColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = primaryColor ?? theme.primaryColor;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: effectivePrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.error_outline_rounded,
              size: 40,
              color: effectivePrimaryColor.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            title ?? "Something went wrong",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Message
          Text(
            message ?? "Please try again.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          if (showRetryButton && onRetry != null) ...[
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                retryButtonText ??
                    "Try Again", // Fixed: Use null-aware operator
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: effectivePrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
