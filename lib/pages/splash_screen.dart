import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'superadmin_dashboard.dart';
import 'staffadmin_dashboard.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Wait for splash then check auth state
    Timer(const Duration(seconds: 2), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No session → go to login
      _goTo(const AdminLoginPage());
      return;
    }

    try {
      // Session exists → check their role in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        // Not an admin anymore → sign out and go to login
        await FirebaseAuth.instance.signOut();
        _goTo(const AdminLoginPage());
        return;
      }

      final role = (doc.data()?['role'] ?? '') as String;

      if (role == 'super_admin') {
        _goTo(const SuperAdminDashboard());
      } else if (role == 'staff_admin') {
        _goTo(const StaffAdminDashboard());
      } else {
        await FirebaseAuth.instance.signOut();
        _goTo(const AdminLoginPage());
      }
    } catch (_) {
      // On any error (e.g. offline), fall back to login
      if (mounted) _goTo(const AdminLoginPage());
    }
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Logo section
            Padding(
              padding: const EdgeInsets.only(top: 80, bottom: 8),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.72,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // "Powered by" text
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.black54),
                children: [
                  TextSpan(
                    text: 'powered by ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'HAPPY TAILS VETERINARY CLINIC',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),

            // Pet image fills the bottom
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/images/splashscreen1.jpg',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
