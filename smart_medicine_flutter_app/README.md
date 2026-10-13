# Smart Medicine & Pharmacy Locator Flutter App

A production-grade Flutter application for medicine discovery, 2-hour pharmacy holds, prescription upload & real-time chemist chat, and pharmacy inventory management across Indian pharmacies (₹ INR pricing).

## Architecture & Tech Stack
- **Framework**: Flutter (SDK: `>=3.3.0 <4.0.0`)
- **Backend & Database**: Firebase Core, Firebase Authentication, Cloud Firestore
- **Maps & Geolocation**: Google Maps Flutter (`google_maps_flutter`), Geolocator (`geolocator`)
- **State Management**: Provider (`provider`)
- **File & Media**: Image Picker (`image_picker`), File Picker (`file_picker`)
- **Security**: Granular Firestore Security Rules (`firestore.rules`) with role-based access control (RBAC for Patients and Pharmacists)

## Project Structure
```
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/AndroidManifest.xml
│   └── build.gradle
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   └── app_strings.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── models/
│   │   ├── chat_message_model.dart
│   │   ├── inventory_model.dart
│   │   ├── medicine_model.dart
│   │   ├── pharmacy_model.dart
│   │   ├── prescription_model.dart
│   │   ├── reservation_model.dart
│   │   ├── user_model.dart
│   │   └── user_role.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── welcome_screen.dart
│   │   ├── medicine/
│   │   │   └── medicine_details_screen.dart
│   │   ├── pharmacy/
│   │   │   ├── pharmacy_dashboard_screen.dart
│   │   │   └── pharmacy_map_screen.dart
│   │   ├── prescription/
│   │   │   ├── my_prescriptions_screen.dart
│   │   │   ├── prescription_chat_screen.dart
│   │   │   ├── prescription_orders_screen.dart
│   │   │   └── upload_prescription_screen.dart
│   │   ├── reservation/
│   │   │   └── reservation_screen.dart
│   │   └── splash/
│   │       └── splash_screen.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── inventory_service.dart
│   │   ├── medicine_service.dart
│   │   ├── prescription_service.dart
│   │   └── reservation_service.dart
│   └── widgets/
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       ├── medical_badge.dart
│       └── medicine_card.dart
├── firestore.rules
└── pubspec.yaml
```

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**:
   - Place `google-services.json` into `android/app/`
   - Place `GoogleService-Info.plist` into `ios/Runner/`
   - Run:
     ```bash
     flutterfire configure
     ```

3. **Configure Google Maps API Key**:
   - Add your key to `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
     ```

4. **Run the Application**:
   ```bash
   flutter run
   ```

5. **Deploy Firestore Security Rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```
