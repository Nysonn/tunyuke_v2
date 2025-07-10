import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/onboarding_controller.dart';
import '../screens/waiting_screen.dart';

class OnboardScheduledRideScreen extends StatefulWidget {
  const OnboardScheduledRideScreen({super.key});

  @override
  _OnboardScheduledRideScreenState createState() =>
      _OnboardScheduledRideScreenState();
}

class _OnboardScheduledRideScreenState
    extends State<OnboardScheduledRideScreen> {
  final TextEditingController _referralCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Listen to controller updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<OnboardingController>(
        context,
        listen: false,
      );

      // Clear any previous data when screen loads
      controller.clearData();

      // Listen to text field changes
      _referralCodeController.addListener(() {
        controller.setReferralCode(_referralCodeController.text);
      });
    });
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  void _joinRide() {
    final controller = Provider.of<OnboardingController>(
      context,
      listen: false,
    );

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Join the ride
    controller.joinRideWithCode().then((_) {
      if (controller.dataError.value == null &&
          controller.joinedRideId.value != null) {
        // Success - navigate to waiting screen with the ride ID
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WaitingScreen(rideId: controller.joinedRideId.value!),
          ),
        );
      } else {
        // Error is already shown via the error display in the UI
        print("Join ride failed: ${controller.dataError.value}");
      }
    });
  }

  void _pasteFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        _referralCodeController.text = data.text!.toUpperCase();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Referral code pasted from clipboard"),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to paste from clipboard"),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<OnboardingController>(context);

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
          "Join a Team Ride",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header info card
              Card(
                elevation: 1,
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_add_rounded,
                        size: 48,
                        color: Colors.blue[600],
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Join an Existing Team Ride",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Enter the referral code shared by your group leader to join their scheduled ride.",
                        style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

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
                        "Enter Referral Code",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Referral code input
                      Text(
                        "Referral Code",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _referralCodeController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "Enter code (e.g., ABC123)",
                          suffixIcon: IconButton(
                            onPressed: _pasteFromClipboard,
                            icon: Icon(Icons.paste, color: theme.primaryColor),
                            tooltip: "Paste from clipboard",
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                          UpperCaseTextFormatter(),
                        ],
                        validator: (value) {
                          return controller.validateReferralCode(value);
                        },
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Helper text
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[600],
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Ask your group leader for the referral code",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Error display
              if (controller.dataError.value != null)
                Card(
                  elevation: 1,
                  color: Colors.red[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.dataError.value!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (controller.dataError.value != null) SizedBox(height: 16),

              // Join button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : _joinRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : Text(
                          "Join Team Ride",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24),

              // Instructions card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "How it works",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildInstructionStep(
                        "1",
                        "Get the referral code from your group leader",
                      ),
                      SizedBox(height: 12),
                      _buildInstructionStep(
                        "2",
                        "Enter the code and tap 'Join Team Ride'",
                      ),
                      SizedBox(height: 12),
                      _buildInstructionStep(
                        "3",
                        "You'll be taken to the ride status screen",
                      ),
                      SizedBox(height: 12),
                      _buildInstructionStep(
                        "4",
                        "Confirm your participation when prompted",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            instruction,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

// Custom text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
