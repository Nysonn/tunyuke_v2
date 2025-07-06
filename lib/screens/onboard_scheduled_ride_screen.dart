import 'package:flutter/material.dart';

class OnboardScheduledRideScreen extends StatelessWidget {
  const OnboardScheduledRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Scheduled Ride')),
      body: const Center(child: Text('Enter code to join an existing ride.')),
    );
  }
}
