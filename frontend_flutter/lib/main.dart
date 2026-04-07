import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/sync_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/farmer_provider.dart';
import 'presentation/providers/crop_provider.dart';
import 'presentation/providers/query_provider.dart';
import 'presentation/screens/session_gate_screen.dart';
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
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const SessionGateScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
