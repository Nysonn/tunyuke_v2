import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:Tunyuke/models/pickup_point.dart';
import 'isolated_map_widget.dart';

class PickupPointsMapView extends StatefulWidget {
  final bool isLoading;
  final String? locationError;
  final LatLng? userLocation;
  final List<PickupPoint> pickupPoints;
  final VoidCallback onRetryLocation;
  final Function(GoogleMapController) onMapCreated;

  const PickupPointsMapView({
    super.key,
    required this.isLoading,
    required this.locationError,
    required this.userLocation,
    required this.pickupPoints,
    required this.onRetryLocation,
    required this.onMapCreated,
  });

  @override
  _PickupPointsMapViewState createState() => _PickupPointsMapViewState();
}

class _PickupPointsMapViewState extends State<PickupPointsMapView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _fadeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.1 * _fadeAnimation.value),
                      Colors.purple.withOpacity(0.05 * _fadeAnimation.value),
                    ],
                  ),
                ),
              );
            },
          ),
          // Loading content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_searching,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        "Finding your location...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 3,
                  child: AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.withOpacity(_fadeAnimation.value),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, color: Colors.red[400], size: 40),
            SizedBox(height: 12),
            Text(
              "Location unavailable",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Unable to access your location. Please check permissions.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.red[600]),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onRetryLocation,
              icon: Icon(Icons.refresh, size: 18),
              label: Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while location is being fetched
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    // Show error state if there's a location error i have changed it to loading state so that our users do not see the error message.
    if (widget.locationError != null) {
      return _buildLoadingState();
    }

    // Show the actual map when location is available
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        child: IsolatedMapWidget(
          userLocation: widget.userLocation,
          pickupPoints: widget.pickupPoints,
          onMapCreated: widget.onMapCreated,
        ),
      ),
    );
  }
}
