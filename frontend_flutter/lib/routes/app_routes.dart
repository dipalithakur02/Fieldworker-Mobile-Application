import 'package:flutter/material.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/farmer_registration_screen.dart';
import '../presentation/screens/farmers_list_screen.dart';
import '../presentation/screens/crop_entry_screen.dart';
import '../presentation/screens/sync_status_screen.dart';
import '../presentation/screens/forgot_password_screen.dart';
import '../presentation/screens/weather_screen.dart';
import '../presentation/screens/crops_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String farmerRegistration = '/farmer-registration';
  static const String farmers = '/farmers';
  static const String cropEntry = '/crop-entry';
  static const String syncStatus = '/sync-status';
  static const String forgotPassword = '/forgot-password';
  static const String weather = '/weather';
  static const String crops = '/crops';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case farmerRegistration:
        return MaterialPageRoute(builder: (_) => FarmerRegistrationScreen());
      case farmers:
        return MaterialPageRoute(builder: (_) => FarmersListScreen());
      case cropEntry:
        final farmerId = settings.arguments as String?;
        if (farmerId == null || farmerId.isEmpty) {
          return MaterialPageRoute(builder: (_) => FarmersListScreen());
        }
        return MaterialPageRoute(builder: (_) => CropEntryScreen(farmerId: farmerId));
      case syncStatus:
        return MaterialPageRoute(builder: (_) => SyncStatusScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case weather:
        return MaterialPageRoute(builder: (_) => WeatherScreen());
      case crops:
        final farmerId = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => CropsScreen(farmerId: farmerId));
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}
