import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/rides_controller.dart';
import '../screens/waiting_screen.dart';
import '../components/common/fallback_screen.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  _RidesScreenState createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  RidesController? _controller;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      try {
        _controller = Provider.of<RidesController>(context, listen: false);
        _controller?.initialize();
        _isInitialized = true;
      } catch (e) {
        print("Error getting RidesController from Provider: $e");
        _controller = null;
      }
    }
  }

  Widget _buildFallbackScreen(RidesController controller, ThemeData theme) {
    final errorType = controller.errorType.value;

    switch (errorType) {
      case "network":
        return FallbackScreen.noConnection(
          onRetry: () => controller.retryFetchUserRides(),
          primaryColor: theme.primaryColor,
        );
      case "server":
        return FallbackScreen.serverError(
          onRetry: () => controller.retryFetchUserRides(),
          primaryColor: theme.primaryColor,
        );
      case "auth":
        return FallbackScreen.unauthorized(
          onRetry: () => Navigator.pushReplacementNamed(context, '/login'),
          retryButtonText: "Login Again",
          primaryColor: theme.primaryColor,
        );
      default:
        return FallbackScreen(
          title: "Failed to Load Rides",
          message: controller.dataError.value ?? "Unable to load your rides",
          icon: Icons.error_outline_rounded,
          onRetry: () => controller.retryFetchUserRides(),
          primaryColor: theme.primaryColor,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If controller is null, show error state
    if (_controller == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: theme.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "My Rides",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: FallbackScreen(
          title: "Controller Error",
          message: "Failed to initialize rides controller. Please try again.",
          icon: Icons.error_outline_rounded,
          onRetry: () => Navigator.pop(context),
          retryButtonText: "Go Back",
          primaryColor: theme.primaryColor,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Rides",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<RidesController>(
        builder: (context, controller, child) {
          if (controller.isLoading.value &&
              controller.userRides.value.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.dataError.value != null) {
            return _buildFallbackScreen(controller, theme);
          }

          if (controller.userRides.value.isEmpty) {
            return FallbackWidget(
              title: "No Rides Found",
              message:
                  "You haven't created any rides yet. Start by scheduling a team ride!",
              icon: Icons.directions_car_outlined,
              showRetryButton: false,
              primaryColor: theme.primaryColor,
            );
          }

          return _buildRidesList(controller.userRides.value);
        },
      ),
    );
  }

  Widget _buildRidesList(List<UserRide> rides) {
    return RefreshIndicator(
      onRefresh: () => _controller!.fetchUserRides(),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return _buildRideCard(ride);
        },
      ),
    );
  }

  Widget _buildRideCard(UserRide ride) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingScreen(rideId: ride.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "From ${ride.pickupName} to ${ride.destName}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ride.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ride.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(ride.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "Participants: ${ride.participantsCount}",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                "Created: ${DateFormat('MMM dd, yyyy - hh:mm a').format(ride.createdAt)}",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Code: ${ride.referralCode}",
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
