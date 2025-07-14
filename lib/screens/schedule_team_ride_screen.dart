import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/schedule_team_ride_controller.dart';
import '../screens/waiting_screen.dart'; // Add this import
// import 'package:google_maps_webservice/places.dart'
//     hide PlacesSearchResult;

class ScheduleTeamRideScreen extends StatefulWidget {
  const ScheduleTeamRideScreen({super.key});

  @override
  _ScheduleTeamRideScreenState createState() => _ScheduleTeamRideScreenState();
}

class _ScheduleTeamRideScreenState extends State<ScheduleTeamRideScreen> {
  final TextEditingController _numberOfTravelersController =
      TextEditingController();
  final TextEditingController _customDestinationTextController =
      TextEditingController(); // For custom destination input
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    // Listen to changes in the controller's custom destination query
    // to keep the text field in sync, especially after a suggestion is selected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ScheduleTeamRideController>(
        context,
        listen: false,
      );
      _customDestinationTextController.addListener(() {
        // Only update controller if the text field's value is different from controller's
        // This prevents infinite loops when controller updates the text field
        if (_customDestinationTextController.text !=
            controller.customDestinationQuery.value) {
          controller.setCustomDestinationQuery(
            _customDestinationTextController.text,
          );
        }
      });

      // Set initial values from controller if they exist (e.g., after navigation back)
      if (controller.numberOfTravelers.value != null) {
        _numberOfTravelersController.text = controller.numberOfTravelers.value
            .toString();
      }
      if (controller.selectedCustomDestination.value != null) {
        _customDestinationTextController.text =
            controller.selectedCustomDestination.value!.name;
      }
    });
  }

  @override
  void dispose() {
    _numberOfTravelersController.dispose();
    _customDestinationTextController.dispose();
    super.dispose();
  }

  void _confirm() {
    final controller = Provider.of<ScheduleTeamRideController>(
      context,
      listen: false,
    );

    // Validate all form fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields correctly."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Additional checks not covered by TextFormField validators
    if (controller.selectedPickupOption.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a pickup option (Current Location or Pickup Station).",
          ),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    if (controller.selectedPickupOption.value == "pickup_station" &&
        controller.selectedPickupStation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a specific pickup station."),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    if (controller.selectedPickupOption.value == "current_location" &&
        controller.currentLocation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please wait for current location to be determined or select a pickup station.",
          ),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    if (controller.selectedDestinationOption.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a destination option (Pickup Station or Custom Destination).",
          ),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    if (controller.selectedDestinationOption.value == "pickup_station" &&
        controller.selectedDestinationStation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a specific destination station."),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    if (controller.selectedDestinationOption.value == "custom_destination" &&
        controller.selectedCustomDestination.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a valid custom destination from the suggestions.",
          ),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    if (controller.desiredDateTime.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a date and time for the ride."),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    // Call the controller method to schedule the ride
    controller.scheduleTeamRide().then((_) {
      if (controller.referralCode.value != null &&
          controller.farePerPerson.value != null) {
        // Navigate to the waiting screen instead
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WaitingScreen(rideId: controller.rideId.value ?? ''),
          ),
        );
      } else if (controller.dataError.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${controller.dataError.value}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _selectDateTime(ScheduleTeamRideController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: controller.desiredDateTime.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          controller.desiredDateTime.value ?? DateTime.now(),
        ),
      );

      if (pickedTime != null) {
        controller.setDesiredDateTime(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<ScheduleTeamRideController>(context);

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
          "Schedule a Team Ride",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: controller.isLoading.value && controller.referralCode.value == null
          ? Center(child: CircularProgressIndicator())
          : controller.dataError.value != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text("Error: ${controller.dataError.value}"),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      controller.dataError.value =
                          null; // Clear error to allow retry
                      controller
                          .initialize(); // Re-initialize to fetch stations
                    },
                    child: Text("Retry"),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
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
                              "Book Your Team Ride",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 24),

                            // Number of Travelers
                            Text(
                              "Number of Travelers",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _numberOfTravelersController,
                              decoration: InputDecoration(
                                hintText: "e.g., 5",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                int? count = int.tryParse(value);
                                controller.setNumberOfTravelers(count);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter the number of travelers.";
                                }
                                int? num = int.tryParse(value);
                                if (num == null || num < 2 || num > 60) {
                                  return "Number of travelers must be between 2 and 60.";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),

                            // Pickup Location
                            Text(
                              "Pickup Location",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Column(
                              children: [
                                RadioListTile<String>(
                                  title: Text("Current Location"),
                                  value: "current_location",
                                  groupValue:
                                      controller.selectedPickupOption.value,
                                  onChanged: (value) =>
                                      controller.setSelectedPickupOption(value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (controller.selectedPickupOption.value ==
                                        "current_location" &&
                                    controller.currentLocation.value == null &&
                                    !controller.isLoading.value)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 16.0,
                                      bottom: 8.0,
                                    ),
                                    child: Text(
                                      controller.dataError.value ??
                                          "Getting current location...",
                                      style: TextStyle(
                                        color:
                                            controller.dataError.value != null
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                if (controller.selectedPickupOption.value ==
                                        "current_location" &&
                                    controller.currentLocation.value != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 16.0,
                                      bottom: 8.0,
                                    ),
                                    child: Text(
                                      "Current Location: Lat ${controller.currentLocation.value!.latitude.toStringAsFixed(4)}, Lng ${controller.currentLocation.value!.longitude.toStringAsFixed(4)}",
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                RadioListTile<String>(
                                  title: Text("Select from Pickup Stations"),
                                  value: "pickup_station",
                                  groupValue:
                                      controller.selectedPickupOption.value,
                                  onChanged: (value) =>
                                      controller.setSelectedPickupOption(value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (controller.selectedPickupOption.value ==
                                    "pickup_station")
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 16.0,
                                      top: 8.0,
                                    ),
                                    child:
                                        DropdownButtonFormField<
                                          TunyukeLocationPoint
                                        >(
                                          value: controller
                                              .selectedPickupStation
                                              .value,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                          items: controller
                                              .tunyukeStations
                                              .value
                                              .map((station) {
                                                return DropdownMenuItem(
                                                  value: station,
                                                  child: Text(station.name),
                                                );
                                              })
                                              .toList(),
                                          onChanged: (value) => controller
                                              .setSelectedPickupStation(value),
                                          validator: (value) =>
                                              (controller
                                                          .selectedPickupOption
                                                          .value ==
                                                      "pickup_station" &&
                                                  value == null)
                                              ? "Please select a station"
                                              : null,
                                        ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),

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
                            Column(
                              children: [
                                RadioListTile<String>(
                                  title: Text("Select from Tunyuke Stations"),
                                  value: "pickup_station",
                                  groupValue: controller
                                      .selectedDestinationOption
                                      .value,
                                  onChanged: (value) => controller
                                      .setSelectedDestinationOption(value),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (controller
                                        .selectedDestinationOption
                                        .value ==
                                    "pickup_station")
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 16.0,
                                      top: 8.0,
                                    ),
                                    child:
                                        DropdownButtonFormField<
                                          TunyukeLocationPoint
                                        >(
                                          value: controller
                                              .selectedDestinationStation
                                              .value,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                          items: controller
                                              .tunyukeStations
                                              .value
                                              .map((station) {
                                                return DropdownMenuItem(
                                                  value: station,
                                                  child: Text(station.name),
                                                );
                                              })
                                              .toList(),
                                          onChanged: (value) => controller
                                              .setSelectedDestinationStation(
                                                value,
                                              ),
                                          validator: (value) =>
                                              (controller
                                                          .selectedDestinationOption
                                                          .value ==
                                                      "pickup_station" &&
                                                  value == null)
                                              ? "Please select a station"
                                              : null,
                                        ),
                                  ),
                                RadioListTile<String>(
                                  title: Text("Enter a Custom Destination"),
                                  value: "custom_destination",
                                  groupValue: controller
                                      .selectedDestinationOption
                                      .value,
                                  onChanged: (value) {
                                    controller.setSelectedDestinationOption(
                                      value,
                                    );
                                    if (value != "custom_destination") {
                                      controller.setSelectedCustomDestination(
                                        null,
                                      );
                                      _customDestinationTextController.clear();
                                    }
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (controller
                                        .selectedDestinationOption
                                        .value ==
                                    "custom_destination")
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 16.0,
                                      top: 8.0,
                                    ),
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller:
                                              _customDestinationTextController,
                                          decoration: InputDecoration(
                                            hintText: "Search destination...",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                            suffixIcon:
                                                controller
                                                        .selectedCustomDestination
                                                        .value !=
                                                    null
                                                ? Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  )
                                                : null,
                                          ),
                                          onChanged: (query) {
                                            // onChanged will trigger setCustomDestinationQuery in controller
                                          },
                                          validator: (value) {
                                            if (controller
                                                        .selectedDestinationOption
                                                        .value ==
                                                    "custom_destination" &&
                                                (value == null ||
                                                    value.isEmpty ||
                                                    controller
                                                            .selectedCustomDestination
                                                            .value ==
                                                        null ||
                                                    controller
                                                            .selectedCustomDestination
                                                            .value!
                                                            .name !=
                                                        value)) {
                                              return "Please select a valid destination from suggestions.";
                                            }
                                            return null;
                                          },
                                        ),
                                        // Display search suggestions
                                        if (controller
                                                    .customDestinationQuery
                                                    .value !=
                                                null &&
                                            controller
                                                .customDestinationQuery
                                                .value!
                                                .isNotEmpty &&
                                            controller
                                                    .selectedCustomDestination
                                                    .value
                                                    ?.name !=
                                                _customDestinationTextController
                                                    .text)
                                          FutureBuilder<
                                            List<PlacesSearchResult>
                                          >(
                                            future: controller.searchPlaces(
                                              controller
                                                  .customDestinationQuery
                                                  .value!,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }
                                              if (snapshot.hasError) {
                                                return Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    "Error fetching suggestions: ${snapshot.error}",
                                                  ),
                                                );
                                              }
                                              if (!snapshot.hasData ||
                                                  snapshot.data!.isEmpty) {
                                                return Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    "No suggestions found.",
                                                  ),
                                                );
                                              }
                                              return Container(
                                                constraints: BoxConstraints(
                                                  maxHeight: 200,
                                                ),
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  itemCount:
                                                      snapshot.data!.length,
                                                  itemBuilder: (context, index) {
                                                    final suggestion =
                                                        snapshot.data![index];
                                                    return ListTile(
                                                      title: Text(
                                                        suggestion.name,
                                                      ),
                                                      leading: Icon(
                                                        Icons.location_on,
                                                      ),
                                                      onTap: () {
                                                        controller
                                                            .setSelectedCustomDestination(
                                                              suggestion,
                                                            );
                                                        _customDestinationTextController
                                                                .text =
                                                            suggestion.name;
                                                        FocusScope.of(
                                                          context,
                                                        ).unfocus();
                                                      },
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Date & Time
                            Text(
                              "Date & Time",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _selectDateTime(controller),
                                icon: Icon(Icons.calendar_today),
                                label: Text(
                                  controller.desiredDateTime.value != null
                                      ? DateFormat(
                                          'MMM dd, yyyy - HH:mm',
                                        ).format(
                                          controller.desiredDateTime.value!,
                                        )
                                      : "Select Date & Time",
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Fare estimate card (if available)
                    if (controller.farePerPerson.value != null)
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
                                "Estimated Fare per Person",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                "UGX ${controller.farePerPerson.value}",
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
                    SizedBox(height: 32),

                    // Confirm Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
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
            ),
    );
  }
}
