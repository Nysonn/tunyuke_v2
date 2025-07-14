# Tunyuke Mobile Application

A Flutter-based mobile application for campus transportation services, connecting students and staff to Kihumuro Campus with convenient ride-sharing options.

## Features

### Authentication
- **Welcome Page**: Clean interface with Tunyuke logo and company branding
- **Sign Up**: Email, username, and password registration
- **Sign In**: Email and password authentication
- **OAuth2 Integration**: Google authentication for seamless login

### Transportation Services

#### To Kihumuro Campus
- **Pickup Stations**: Mile 3, Mile 4, Rwebikona, Town
- **Schedule**: Morning departures (7:00 AM - 8:00 AM)
- **Ready Times**:
  - Town: 7:15 AM
  - Rwebikona: 7:20 AM
  - Mile 3: 7:25 AM
  - Mile 4: 7:30 AM

#### From Kihumuro Campus
- **Multiple Destinations**: Mile 3, Mile 4, Rwebikona, Town
- **Schedule**: Evening departures (6:00 PM - 7:00 PM)
- **Ready Time**: 6:00 PM at campus

#### Team Rides
- **Schedule Team Rides**: Create group transportation with custom timing
- **Join Team Rides**: Use referral codes to join existing group rides
- **Shared Cost**: Automatically calculated per-person pricing

### Payment Options
- **Mobile Money**: MTN Mobile Money, Airtel Money
- **Card Payments**: Integrated payment gateway
- **Secure Processing**: All transactions processed securely

## Technology Stack

- **Frontend**: Flutter & Dart
- **Backend**: Firebase
- **Authentication**: Firebase Auth with OAuth2
- **Database**: Firestore
- **Payments**: Mobile Money Integration

## App Flow

### Main Dashboard
Four primary options available to users:
1. **To Kihumuro Campus** - Book rides to campus
2. **From Kihumuro Campus** - Book return trips
3. **Schedule a Team Ride** - Create group transportation
4. **Onboard on a Scheduled Team Ride** - Join existing group rides

### Booking Process
1. **Route Selection** - Choose pickup/destination
2. **Time Confirmation** - Verify travel schedule
3. **Payment** - Secure payment processing
4. **Confirmation** - Receive booking confirmation

### Team Ride Process
1. **Create Ride** - Set group size, destination, and timing
2. **Share Code** - Distribute referral code to group members
3. **Group Confirmation** - All members confirm participation
4. **Payment** - Split payment processing for all participants

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Firebase project setup
- Mobile Money payment gateway credentials

### Installation

1. Clone the repository
```bash
git clone https://github.com/Nysonn/tunyuke_v2
cd tunyuke_v2
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Configure Firebase Authentication and Firestore

4. Run the application
```bash
flutter run
```

## Key Features Implementation

### Authentication Flow
- Firebase Authentication with email/password
- Google OAuth2 integration
- Secure session management

### Ride Management
- Real-time ride status updates
- Automated pricing calculation
- Group ride coordination with referral codes

### Payment Integration
- Mobile Money payment processing
- Transaction history tracking
- Receipt generation

## Operating Hours

- **Morning Service**: 7:00 AM - 8:00 AM (to campus)
- **Evening Service**: 6:00 PM - 7:00 PM (from campus)
- **Team Rides**: Flexible scheduling based on user preferences

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## Support

For support and inquiries, please contact the Tunyuke team or create an issue in this repository.

---

*Tunyuke - Connecting you to Kihumuro Campus efficiently and affordably.*