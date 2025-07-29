import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/rides_controller.dart';
import 'waiting_screen.dart';
import '../components/common/ride_time_formatter.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  _RidesScreenState createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      // Convert to local timezone if needed
      final localDate = date.toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(localDate);
    } catch (e) {
      return dateString;
    }
  }

  String _formatRideTime(String? rideTime) {
    if (rideTime == null || rideTime.isEmpty) return 'N/A';
    return formatRideTime(rideTime);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'active':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      case 'active':
        return Icons.radio_button_checked;
      default:
        return Icons.help;
    }
  }

  Widget _buildRideCard({
    required String title,
    required String subtitle,
    required String status,
    required String time,
    required int fare,
    required String rideType,
    VoidCallback? onTap,
  }) {
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Ride Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rideType,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Row
                Row(
                  children: [
                    // Time
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        time,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),

                    // Fare
                    if (fare > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 14,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "UGX $fare",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRidesList(RidesController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshRides,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller.campusRides.value.isNotEmpty) ...[
            _buildSectionHeader('To Campus'),
            ...controller.campusRides.value.map(
              (ride) => _buildRideCard(
                title: "To ${ride['pickup_station'] ?? 'Campus'}",
                subtitle: "Ride Time: ${_formatRideTime(ride['ride_time'])}",
                status: ride['status'] ?? 'pending',
                time: _formatDate(ride['created_at'] ?? ''),
                fare: ride['fare'] ?? 0,
                rideType: 'To Campus',
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (controller.fromCampusRides.value.isNotEmpty) ...[
            _buildSectionHeader('From Campus'),
            ...controller.fromCampusRides.value.map(
              (ride) => _buildRideCard(
                title: "To ${ride['destination'] ?? 'Destination'}",
                subtitle: "Ride Time: ${_formatRideTime(ride['ride_time'])}",
                status: ride['status'] ?? 'pending',
                time: _formatDate(ride['created_at'] ?? ''),
                fare: ride['fare'] ?? 0,
                rideType: 'From Campus',
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (controller.scheduledRides.value.isNotEmpty) ...[
            _buildSectionHeader('Scheduled Rides'),
            ...controller.scheduledRides.value.map(
              (ride) => _buildRideCard(
                title:
                    "${ride['pickup_name'] ?? 'Pickup'} → ${ride['dest_name'] ?? 'Destination'}",
                subtitle:
                    "Seats: ${ride['seats'] ?? 0} • Code: ${ride['referral_code'] ?? 'N/A'}",
                status: ride['status'] ?? 'pending',
                time: _formatDate(ride['scheduled_at'] ?? ''),
                fare: ride['fare'] ?? 0,
                rideType: 'Team Ride',
                onTap: () {
                  // Navigate to waiting screen with this ride's ID
                  if (ride['id'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WaitingScreen(rideId: ride['id']),
                      ),
                    );
                  } else {
                    // Show error if ride ID is missing
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Cannot view ride details: Missing ride ID",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'You have not booked any rides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by booking your first ride!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Book a Ride',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "My Rides",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<RidesController>(
            builder: (context, controller, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: controller.isRefreshing.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: controller.isRefreshing.value
                      ? null
                      : () => controller.refreshRides(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<RidesController>(
        builder: (context, controller, child) {
          // Show loading state
          if (controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading your rides...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Show refreshing state with overlay
          if (controller.isRefreshing.value) {
            return Stack(
              children: [
                _buildRidesList(controller),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
              ],
            );
          }

          // Handle error states
          if (controller.error.value != null) {
            // Special case for "no rides" - show a friendly message
            if (controller.isNoRidesError) {
              return _buildEmptyState();
            }

            // Show error with retry option
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Something went wrong",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.error.value!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => controller.fetchAllRides(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Try Again",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildRidesList(controller);
        },
      ),
    );
  }
}
