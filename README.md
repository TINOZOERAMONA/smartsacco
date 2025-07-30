# smartloan_sacco

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

A comprehensive SACCO (Savings and Credit Cooperative Organization) management application designed specifically for **blind and visually impaired users** with voice-first navigation, enhanced security, and complete MTN Mobile Money API integration.

## 🎯 Project Overview

SmartSacco is a Flutter-based mobile application that provides a complete SACCO management solution with:

- **🎤 Voice-First Navigation**: Voice command system for blind users
- **💳 MTN Mobile Money Integration**: Full payment processing via MTN API
- **📊 Comprehensive Analytics**: Real-time tracking and reporting
- **♿ Accessibility Features**: Screen reader support and voice feedback
- **🌐 Multi-Platform**: Android, iOS, Web, and Desktop support
### 🎤 Voice Navigation System
- **Voice Commands**: Natural language processing for app functions
- **Speech Synthesis**: Customizable text-to-speech with multiple voice configurations
- **Error Recovery**: Intelligent retry mechanisms and graceful fallbacks
- **Contextual Help**: Voice-guided assistance throughout the application

### 💰 Financial Management
- **Deposits**: Voice-activated deposits via MTN Mobile Money

- **Balance Checking**: Real-time account balance with voice feedback
- **Transaction History**: Complete transaction tracking and reporting

### 🔐 Security & Authentication
- **Firebase Authentication**: Secure user registration and login
- **Role-Based Access**: Admin and member role management
- **PIN Protection**: Voice PIN entry for blind users
- **Session Management**: Secure session handling and timeout
- **Data Encryption**: Encrypted data storage and transmission

### 📱 User Experience
- **Voice Settings**: Customizable speech rate, pitch.
- **Error Handling**: User-friendly error messages with voice feedback
- **Deep Linking**: Email verification and password reset via deep links

## 🏗️ Architecture

### Core Services
```
lib/
├── services/
│   ├── enhanced_voice_service.dart      # Voice recognition & synthesis
│   ├── momoservices.dart                # MTN Mobile Money API
│   ├── payment_service.dart             # Payment processing
│   ├── auth.dart                        # Authentication service
│   ├── accessibility_service.dart       # Accessibility features
│   ├── analytics_service.dart           # User analytics
│   ├── notification_service.dart        # Push notifications
│   └── user_preferences_service.dart    # User settings
├── pages/
│   ├── splash_page.dart                 # Voice-enabled splash screen
│   ├── voicewelcome.dart                # Voice navigation welcome
│   ├── blinddashboard.dart              # Main voice dashboard
│   ├── voicelogin.dart                  # Voice login system
│   ├── voiceregister.dart               # Voice registration
│   ├── member_dashboard.dart            # Member dashboard
│   └── admin/                           # Admin management pages
├── models/                              # Data models
├── config/                              # Configuration files
└── utils/                               # Utility functions
```

### Technology Stack
- **Frontend**: Flutter 3.32.6
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Payment**: MTN Mobile Money API
- **Voice**: Flutter TTS + Speech to Text
- **Analytics**: Custom analytics service
- **Notifications**: Firebase Cloud Messaging

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.32.6 or higher
- Dart SDK 3.8.0 or higher
- Android Studio / VS Code
- Firebase project setup
- MTN API credentials

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/smartsacco.git
   cd smartsacco
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase**
   - Create a Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories
   - Enable Authentication, Firestore, and Storage

4. **Configure MTN API**
   - Update `lib/config/mtn_api_config.dart` with your MTN API credentials
   - Set up webhook server for payment callbacks
   - Configure sandbox/production environment

5. **Run the application**
   ```bash
   flutter run
   ```

   ### Environment Configuration

#### Firebase Setup
```dart
// lib/firebase_options.dart
// Configure your Firebase project settings
```

#### MTN API Configuration
```dart
// lib/config/mtn_api_config.dart
class MTNApiConfig {
  static const String collectionSubscriptionKey = 'your_key';
  static const String collectionApiUser = 'your_user';
  static const String collectionApiKey = 'your_api_key';
  static const bool isSandbox = true; // Set to false for production
}
```

## 🎤 Voice Navigation Guide

### Getting Started with Voice
1. **Launch the app** - Voice welcome message plays automatically
2. **Say "one"** - Activates voice navigation mode
3. **Follow voice prompts** - Navigate through all features using voice commands

### Voice Commands

#### Navigation Commands
- `"one"` - Activate voice navigation
- `"go to dashboard"` - Navigate to main dashboard
#### Financial Commands
- `"make deposit"` - Start deposit process
- `"make withdrawal"` - Start withdrawal process
- `"check balance"` - Get current balance
- `"view transactions"` - Show transaction history
- `"apply for loan"` - Start loan application


### MTN Mobile Money Features
- **Request to Pay**: Collection API for deposits
- **Transfer**: Disbursement API for withdrawals
- **Balance Checking**: Real-time account balance
- **Transaction Status**: Live transaction monitoring
- **Phone Validation**: Automatic phone number formatting

### Payment Flow
1. **User initiates payment** via voice command
2. **System validates** phone number and amount
3. **MTN API request** sent with proper authentication
4. **Transaction status** monitored in real-time
5. **Confirmation** sent via voice and notification
6. **Database updated** with transaction details

### Supported Operations
- ✅ Deposits (Request to Pay)
- ✅ Withdrawals (Transfer)
- ✅ Balance Inquiries
- ✅ Transaction History
- ✅ Payment Status Tracking
- ✅ Phone Number Validation

## 🔐 Security Features

### Authentication
- **Firebase Authentication**: Email/password and anonymous auth
- **Voice PIN System**: Secure PIN entry for blind users
- **Session Management**: Automatic session timeout
- **Role-Based Access**: Admin and member permissions


### Data Protection
- **Encrypted Storage**: Secure local data storage
- **API Security**: Signed requests to MTN API
- **Input Validation**: Comprehensive data validation
- **Error Handling**: Secure error messages

### Privacy
- **Data Minimization**: Only necessary data collected
- **User Control**: Full control over personal data
- **Transparency**: Clear data usage policies
- **Compliance**: GDPR and local privacy law compliance