import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/medicine/medicine_details_screen.dart';
import 'screens/prescription/upload_prescription_screen.dart';
import 'screens/prescription/prescription_chat_screen.dart';
import 'screens/prescription/prescription_orders_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

class SmartMedicineApp extends StatelessWidget {
  const SmartMedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/medicine-details': (context) => const MedicineDetailsScreen(),
        '/upload-prescription': (context) => const UploadPrescriptionScreen(),
        '/prescription-chat': (context) => const PrescriptionChatScreen(),
        '/prescription-orders': (context) => const PrescriptionOrdersScreen(),
      },
    );
  }
}
