import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/sync_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/farmer_provider.dart';
import 'presentation/providers/crop_provider.dart';
import 'presentation/providers/query_provider.dart';
import 'presentation/screens/session_gate_screen.dart';
import 'presentation/widgets/field_steward_ui.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SyncService.initialize();
  SyncService.registerPeriodicSync();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FarmerProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => QueryProvider()),
      ],
      child: MaterialApp(
        title: 'Fieldworker App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: FieldStewardColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: FieldStewardColors.primary,
            primary: FieldStewardColors.primary,
            surface: FieldStewardColors.background,
            error: FieldStewardColors.error,
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: FieldStewardColors.onSurface,
            ),
            headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: FieldStewardColors.onSurface,
            ),
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: FieldStewardColors.onSurface,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: FieldStewardColors.onSurface,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: FieldStewardColors.onSurfaceVariant,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: FieldStewardColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: const SessionGateScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
