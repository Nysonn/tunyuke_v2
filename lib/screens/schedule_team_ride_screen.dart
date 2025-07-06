import 'package:flutter/material.dart';

class ScheduleTeamRideScreen extends StatelessWidget {
  const ScheduleTeamRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule a Team Ride')),
      body: const Center(child: Text('Options for scheduling team rides.')),
    );
  }
}
