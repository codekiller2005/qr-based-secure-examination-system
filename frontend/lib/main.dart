import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/exam_provider.dart';
import 'core/providers/qr_provider.dart';
import 'core/services/invigilator_service.dart';
import 'core/providers/invigilator_provider.dart';
import 'core/services/admin_service.dart';
import 'core/providers/admin_provider.dart';
import 'presentations/routes/app_routes.dart';
void main() async {
  // Ensure Flutter engine binding initializes before executing async resources
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize shared preferences local cache
  final sharedPrefs = await SharedPreferences.getInstance();
  final storageService = StorageService(sharedPrefs);
  // Setup networking and inject storage dependency
  final apiService = ApiService(storageService);
  final invigilatorService = InvigilatorService(apiService);
  final adminService = AdminService(apiService);
  runApp(
    MultiProvider(
      providers: [
        // Inject core storage services
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),
        Provider<InvigilatorService>.value(value: invigilatorService),
        Provider<AdminService>.value(value: adminService),
        
        // Register AuthProvider change notifier
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(apiService, storageService),
        ),
        
        // Register ExamProvider change notifier
        ChangeNotifierProvider<ExamProvider>(
          create: (context) => ExamProvider(),
        ),
        // Register QRProvider change notifier
        ChangeNotifierProvider<QRProvider>(
          create: (context) => QRProvider(apiService),
        ),
        // Register InvigilatorProvider change notifier
        ChangeNotifierProvider<InvigilatorProvider>(
          create: (context) => InvigilatorProvider(invigilatorService),
        ),
        // Register AdminProvider change notifier
       ChangeNotifierProvider<AdminProvider>(
  create: (context) => AdminProvider(
    context.read<AdminService>(),
  ),
),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return MaterialApp(
      title: 'Secure Offline Examination System',
      debugShowCheckedModeBanner: false,
      
      // Setup Premium Dark Slate Styling Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
          background: Color(0xFF0F172A),
          error: Color(0xFFEF4444),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF334155)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
        ),
      ),
      
      // Determine startup entrypoint depending on active sessions
      initialRoute: authProvider.isAuthenticated 
          ? _getDashboardRoute(authProvider.role) 
          : AppRoutes.login,
          
      routes: AppRoutes.routes,
    );
  }
  /// Helper to route active sessions dynamically upon app boot.
  String _getDashboardRoute(String? role) {
    switch (role) {
      case 'admin':
        return AppRoutes.adminDashboard;
      case 'invigilator':
        return AppRoutes.invigilatorDashboard;
      case 'student':
      default:
        return AppRoutes.studentDashboard;
    }
  }
}
