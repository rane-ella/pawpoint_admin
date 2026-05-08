import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:pawpoint_admin/pages/login_page.dart';
import 'package:pawpoint_admin/pages/splash_screen.dart';
import 'package:pawpoint_admin/pages/superadmin_dashboard.dart';
import 'package:pawpoint_admin/pages/staffadmin_dashboard.dart';
import 'package:pawpoint_admin/pages/verify_email_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawAdmin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const AdminLoginPage(),
        '/super_admin': (context) => const SuperAdminDashboard(),
        '/staff_admin': (context) => const StaffAdminDashboard(),
        '/verify-email': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return VerifyAdminEmailPage(role: args['role']);
        },
      },
    );
  }
}
