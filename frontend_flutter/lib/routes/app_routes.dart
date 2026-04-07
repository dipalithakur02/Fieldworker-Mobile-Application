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
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/queries_screen.dart';
import '../presentation/screens/query_create_screen.dart';
import '../data/models/farmer_model.dart';
import '../data/models/crop_model.dart';

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
  static const String profile = '/profile';
  static const String queries = '/queries';
  static const String queryCreate = '/query-create';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case farmerRegistration:
        final farmer = settings.arguments as FarmerModel?;
        return MaterialPageRoute(
          builder: (_) => FarmerRegistrationScreen(existingFarmer: farmer),
        );
      case farmers:
        return MaterialPageRoute(builder: (_) => const FarmersListScreen());
      case cropEntry:
        final args = settings.arguments;
        final farmerId = args is String
            ? args
            : args is Map<String, dynamic>
                ? args['farmerId'] as String? ??
                    (args['crop'] as CropModel?)?.farmerId
                : null;
        final crop =
            args is Map<String, dynamic> ? args['crop'] as CropModel? : null;
        if (farmerId == null || farmerId.isEmpty) {
          return MaterialPageRoute(builder: (_) => const FarmersListScreen());
        }
        return MaterialPageRoute(
          builder: (_) => CropEntryScreen(
            farmerId: farmerId,
            existingCrop: crop,
          ),
        );
      case syncStatus:
        return MaterialPageRoute(builder: (_) => SyncStatusScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case weather:
        return MaterialPageRoute(builder: (_) => WeatherScreen());
      case crops:
        final farmerId = settings.arguments as String?;
        return MaterialPageRoute(
            builder: (_) => CropsScreen(farmerId: farmerId));
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case queries:
        return MaterialPageRoute(builder: (_) => const QueriesScreen());
      case queryCreate:
        final crop = settings.arguments as CropModel?;
        if (crop == null) {
          return MaterialPageRoute(builder: (_) => const CropsScreen());
        }
        return MaterialPageRoute(
          builder: (_) => QueryCreateScreen(crop: crop),
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
