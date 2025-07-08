import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/to_campus_controller.dart';

class FromCampusPage extends StatefulWidget {
  const FromCampusPage({super.key});

  @override
  _FromCampusPageState createState() => _FromCampusPageState();
}

class _FromCampusPageState extends State<FromCampusPage> {
  String? _selectedDestination;
  String? _selectedRideTime;

  @override
  void initState() {
    super.initState();
  }

  void _confirm() {
    final controller = Provider.of<ToCampusController>(context, listen: false);

    if (_selectedDestination == null || _selectedRideTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a destination and ride time."),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    int fare = controller.prices.value[_selectedDestination] ?? 0;

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        "fare": fare,
        "destination": _selectedDestination,
        "rideTime": _selectedRideTime,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toCampusController = Provider.of<ToCampusController>(context);

    // Set initial dropdown values once data is loaded
    if (_selectedDestination == null &&
        toCampusController.pickupStations.value.isNotEmpty) {
      _selectedDestination = toCampusController.pickupStations.value.first;
    }
    if (_selectedRideTime == null &&
        toCampusController.rideTimes.value.isNotEmpty) {
      _selectedRideTime = toCampusController.rideTimes.value.first;
    }

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
          "From Kihumuro Campus",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: toCampusController.isLoading.value
          ? Center(child: CircularProgressIndicator())
          : toCampusController.dataError.value != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text("Error: ${toCampusController.dataError.value}"),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main form card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Book Your Ride",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 24),

                          // Destination
                          Text(
                            "Destination",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedDestination,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: toCampusController.pickupStations.value.map((
                              destination,
                            ) {
                              return DropdownMenuItem(
                                value: destination,
                                child: Text(destination),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDestination = value;
                              });
                            },
                          ),
                          SizedBox(height: 20),

                          // Ride Time
                          Text(
                            "Departure Time",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedRideTime,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: toCampusController.rideTimes.value.map((
                              time,
                            ) {
                              return DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRideTime = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Price card
                  if (_selectedDestination != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Fare",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              "UGX ${toCampusController.prices.value[_selectedDestination] ?? 0}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),

                  // Ready time info
                  if (_selectedRideTime != null && _selectedDestination != null)
                    Card(
                      elevation: 1,
                      color: Colors.amber[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber[700],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedRideTime?.startsWith("Morning") ??
                                        false
                                    ? "Be ready by ${toCampusController.morningReadyTimes.value[_selectedDestination ?? ""] ?? "7:00 am"}"
                                    : "Be ready by ${toCampusController.eveningReadyTime.value}",
                                style: TextStyle(
                                  color: Colors.amber[800],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 32),

                  // Confirm button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Confirm Booking",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
