String formatRideTime(String rideTime) {
  final regex = RegExp(r'(\w+)\s+\((\d+)–(\d+)\s*(am|pm)\)');
  final match = regex.firstMatch(rideTime);
  if (match != null) {
    final period = match.group(1); // e.g., Morning
    final start = match.group(2);  // e.g., 7
    final end = match.group(3);    // e.g., 8
    final ampm = match.group(4);   // e.g., am
    return ' $period, from $start to $end $ampm';
  }
  return rideTime; // fallback if format doesn't match
} 