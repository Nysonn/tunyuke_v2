import 'package:Tunyuke/models/pickup_point.dart';
import 'package:flutter/material.dart';
import 'package:Tunyuke/controllers/dashboard_controller.dart';
import 'package:Tunyuke/components/dashboard/dashboard_app_bar.dart';
import 'package:Tunyuke/components/dashboard/dashboard_cards_grid.dart';
import 'package:Tunyuke/components/dashboard/dashboard_bottom_nav_bar.dart';
import 'package:Tunyuke/components/dashboard/pickup_points_map_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late DashboardController _dashboardController;
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late List<Animation<double>> _cardAnimations;

  GoogleMapController? _mapController; // Controller for the Google Map

  @override
  void initState() {
    super.initState();

    _dashboardController = DashboardController();
    _dashboardController.addListener(_onControllerChange);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _cardAnimations = List.generate(
      _dashboardController.dashboardCardsData.length,
      (index) {
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              index * 0.1,
              0.4 + (index * 0.1),
              curve: Curves.easeOutBack,
            ),
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _staggerController.forward();
        }
      });
    });
  }

  void _onControllerChange() {
    setState(() {
      // Rebuild the UI when any ValueNotifier in the controller changes
      // Also, animate camera to user location if it becomes available
      // and map controller is ready.
      if (_dashboardController.userLocation.value != null &&
          _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            _dashboardController.userLocation.value!,
            14.0, // Zoom closer to user
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _dashboardController.removeListener(_onControllerChange);
    _dashboardController.dispose();
    _fadeController.dispose();
    _staggerController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ValueListenableBuilder<String>(
          valueListenable: _dashboardController.currentTimeGreeting,
          builder: (context, greeting, child) {
            return ValueListenableBuilder<String>(
              valueListenable: _dashboardController.userName,
              builder: (context, userName, child) {
                return DashboardAppBar(
                  greeting: greeting,
                  userName: userName,
                  theme: theme,
                );
              },
            );
          },
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- Map Section using the new widget ---
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _dashboardController.isLocationLoading,
                      builder: (context, isLoading, child) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: _dashboardController.locationError,
                          builder: (context, error, child) {
                            return ValueListenableBuilder<LatLng?>(
                              valueListenable:
                                  _dashboardController.userLocation,
                              builder: (context, userLocation, child) {
                                return ValueListenableBuilder<
                                  List<PickupPoint>
                                >(
                                  valueListenable:
                                      _dashboardController.pickupPoints,
                                  builder: (context, pickupPoints, child) {
                                    return PickupPointsMapView(
                                      isLoading: isLoading,
                                      locationError: error,
                                      userLocation: userLocation,
                                      pickupPoints: pickupPoints,
                                      onRetryLocation:
                                          _dashboardController.refreshMapData,
                                      onMapCreated: (controller) {
                                        _mapController = controller;
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.0),

                  // --- Main Action Cards (Existing Section) ---
                  Expanded(
                    child: DashboardCardsGrid(
                      cardsData: _dashboardController.dashboardCardsData,
                      cardAnimations: _cardAnimations,
                      onCardTapped: (routeName) => _dashboardController
                          .onDashboardCardTapped(context, routeName),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _dashboardController.currentIndex,
        builder: (context, currentIndex, child) {
          return DashboardBottomNavBar(
            currentIndex: currentIndex,
            onItemTapped: (index) =>
                _dashboardController.onBottomNavItemTapped(index, context),
            theme: theme,
          );
        },
      ),
    );
  }
}
