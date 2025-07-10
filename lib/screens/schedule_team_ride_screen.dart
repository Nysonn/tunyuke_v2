import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/schedule_team_ride_controller.dart';
import 'package:google_maps_webservice/places.dart'
    hide PlacesSearchResult; // Import for PlacesSearchResult

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
        const SnackBar(
          content: Text(
            "Please select a pickup option (Current Location or Pickup Station).",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (controller.selectedPickupOption.value == "pickup_station" &&
        controller.selectedPickupStation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a specific pickup station."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (controller.selectedPickupOption.value == "current_location" &&
        controller.currentLocation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please wait for current location to be determined or select a pickup station.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (controller.selectedDestinationOption.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a destination option (Pickup Station or Custom Destination).",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (controller.selectedDestinationOption.value == "pickup_station" &&
        controller.selectedDestinationStation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a specific destination station."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (controller.selectedDestinationOption.value == "custom_destination" &&
        controller.selectedCustomDestination.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a valid custom destination from the suggestions.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (controller.desiredDateTime.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a date and time for the ride."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Call the controller method to schedule the ride
    controller.scheduleTeamRide().then((_) {
      if (controller.referralCode.value != null &&
          controller.farePerPerson.value != null) {
        // Navigate to the next screen (SharedRideCodePage)
        Navigator.pushNamed(
          context,
          '/shared_ride_code',
          arguments: {
            "referralCode": controller.referralCode.value,
            "farePerPerson": controller.farePerPerson.value,
            "numberOfTravelers": controller.numberOfTravelers.value,
            "destination":
                controller.selectedDestinationOption.value ==
                    "custom_destination"
                ? controller.selectedCustomDestination.value!.name
                : controller
                      .selectedDestinationStation
                      .value!
                      .name, // Use .name for TunyukeLocationPoint
            "desiredDateTime": controller.desiredDateTime.value,
          },
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
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
          ? const Center(child: CircularProgressIndicator())
          : controller.dataError.value != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${controller.dataError.value}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      controller.dataError.value =
                          null; // Clear error to allow retry
                      controller
                          .initialize(); // Re-initialize to fetch stations
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : Form(
              // Wrap with Form for validation
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Number of Travelers
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Number of Travelers",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _numberOfTravelersController,
                              decoration: InputDecoration(
                                labelText:
                                    "How many people are you traveling with?",
                                hintText: "e.g., 5",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.people_outline),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pickup Options
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pickup Location",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RadioListTile<String>(
                              title: const Text("Current Location"),
                              value: "current_location",
                              groupValue: controller.selectedPickupOption.value,
                              onChanged: (value) =>
                                  controller.setSelectedPickupOption(value),
                            ),
                            if (controller.selectedPickupOption.value ==
                                    "current_location" &&
                                controller.currentLocation.value == null &&
                                !controller.isLoading.value)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  bottom: 8.0,
                                ),
                                child: Text(
                                  controller.dataError.value ??
                                      "Getting current location...",
                                  style: TextStyle(
                                    color: controller.dataError.value != null
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            if (controller.selectedPickupOption.value ==
                                    "current_location" &&
                                controller.currentLocation.value != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  bottom: 8.0,
                                ),
                                child: Text(
                                  "Current Location: Lat ${controller.currentLocation.value!.latitude.toStringAsFixed(4)}, Lng ${controller.currentLocation.value!.longitude.toStringAsFixed(4)}",
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            RadioListTile<String>(
                              title: const Text("Select from Pickup Stations"),
                              value: "pickup_station",
                              groupValue: controller.selectedPickupOption.value,
                              onChanged: (value) =>
                                  controller.setSelectedPickupOption(value),
                            ),
                            if (controller.selectedPickupOption.value ==
                                "pickup_station")
                              DropdownButtonFormField<TunyukeLocationPoint>(
                                value: controller.selectedPickupStation.value,
                                decoration: InputDecoration(
                                  labelText: "Pickup Station",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.location_on),
                                ),
                                items: controller.tunyukeStations.value.map((
                                  station,
                                ) {
                                  return DropdownMenuItem(
                                    value: station,
                                    child: Text(station.name),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    controller.setSelectedPickupStation(value),
                                validator: (value) =>
                                    (controller.selectedPickupOption.value ==
                                            "pickup_station" &&
                                        value == null)
                                    ? "Please select a station"
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Destination Options
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Destination",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RadioListTile<String>(
                              title: const Text("Select from Tunyuke Stations"),
                              value:
                                  "pickup_station", // Reusing "pickup_station" for Tunyuke's predefined points
                              groupValue:
                                  controller.selectedDestinationOption.value,
                              onChanged: (value) => controller
                                  .setSelectedDestinationOption(value),
                            ),
                            RadioListTile<String>(
                              title: const Text("Enter a Custom Destination"),
                              value: "custom_destination",
                              groupValue:
                                  controller.selectedDestinationOption.value,
                              onChanged: (value) {
                                controller.setSelectedDestinationOption(value);
                                if (value != "custom_destination") {
                                  controller.setSelectedCustomDestination(null);
                                  _customDestinationTextController.clear();
                                }
                              },
                            ),
                            if (controller.selectedDestinationOption.value ==
                                "pickup_station")
                              DropdownButtonFormField<TunyukeLocationPoint>(
                                value:
                                    controller.selectedDestinationStation.value,
                                decoration: InputDecoration(
                                  labelText: "Destination Station",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.location_city),
                                ),
                                items: controller.tunyukeStations.value.map((
                                  station,
                                ) {
                                  return DropdownMenuItem(
                                    value: station,
                                    child: Text(station.name),
                                  );
                                }).toList(),
                                onChanged: (value) => controller
                                    .setSelectedDestinationStation(value),
                                validator: (value) =>
                                    (controller
                                                .selectedDestinationOption
                                                .value ==
                                            "pickup_station" &&
                                        value == null)
                                    ? "Please select a station"
                                    : null,
                              ),
                            if (controller.selectedDestinationOption.value ==
                                "custom_destination")
                              Column(
                                children: [
                                  TextFormField(
                                    controller:
                                        _customDestinationTextController,
                                    decoration: InputDecoration(
                                      labelText: "Search Destination",
                                      hintText: "e.g., Kampala Road",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon:
                                          controller
                                                  .selectedCustomDestination
                                                  .value !=
                                              null
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                          : null,
                                    ),
                                    onChanged: (query) {
                                      // onChanged will trigger setCustomDestinationQuery in controller
                                      // which then triggers FutureBuilder
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
                                  if (controller.customDestinationQuery.value !=
                                          null &&
                                      controller
                                          .customDestinationQuery
                                          .value!
                                          .isNotEmpty &&
                                      controller
                                              .selectedCustomDestination
                                              .value
                                              ?.name !=
                                          _customDestinationTextController.text)
                                    FutureBuilder<List<PlacesSearchResult>>(
                                      future: controller.searchPlaces(
                                        controller
                                            .customDestinationQuery
                                            .value!,
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "Error fetching suggestions: ${snapshot.error}",
                                            ),
                                          );
                                        }
                                        if (!snapshot.hasData ||
                                            snapshot.data!.isEmpty) {
                                          return const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              "No suggestions found.",
                                            ),
                                          );
                                        }
                                        return Container(
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (context, index) {
                                              final suggestion =
                                                  snapshot.data![index];
                                              return ListTile(
                                                title: Text(suggestion.name),
                                                leading: const Icon(
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
                                                  ).unfocus(); // Close keyboard
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date & Time Picker
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Date & Time",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _selectDateTime(controller),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                controller.desiredDateTime.value != null
                                    ? DateFormat('MMM dd, yyyy - HH:mm').format(
                                        controller.desiredDateTime.value!,
                                      )
                                    : "Select Date & Time",
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Confirm Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : _confirm, // Disable while loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 5,
                        ),
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Confirm Ride",
                                style: TextStyle(
                                  fontSize: 18,
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
