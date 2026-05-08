import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../services/admin_api_service.dart';

class VerifyAdminEmailPage extends StatefulWidget {
  final String role;
  const VerifyAdminEmailPage({super.key, required this.role});

  @override
  State<VerifyAdminEmailPage> createState() => _VerifyAdminEmailPageState();
}

class _VerifyAdminEmailPageState extends State<VerifyAdminEmailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _autoCheckTimer;
  bool _isVerifying = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await _auth.currentUser?.reload();
      if (_auth.currentUser?.emailVerified == true) {
        _autoCheckTimer?.cancel();
        _activateAndProceed();
      }
    });
  }

  Future<void> _activateAndProceed() async {
    final uid = _auth.currentUser!.uid;

    // Activate the account in Firestore
    try {
      await AdminApiService.markStaffActive(uid);
    } catch (e) {
      debugPrint('Activation failed: $e');
    }

    if (!mounted) return;

    // Route based on role
    if (widget.role == 'super_admin') {
      Navigator.pushNamedAndRemoveUntil(context, '/super_admin', (_) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/staff_admin', (_) => false);
    }
  }

  Future<void> _resendVerification() async {
    if (!_canResend) return;

    try {
      await _auth.currentUser?.sendEmailVerification();
      _showSnack('Verification email sent!', isError: false);

      setState(() {
        _canResend = false;
        _resendCooldown = 60;
      });

      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      });
    } catch (e) {
      _showSnack('Failed to resend: ${e.toString()}');
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 30),
              Text(
                'Verify Your Email',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'A verification link has been sent to your email. Please click the link to activate your account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              if (_isVerifying)
                const CircularProgressIndicator()
              else
                AppButton(
                  text: 'I HAVE VERIFIED',
                  onPressed: () async {
                    setState(() => _isVerifying = true);
                    await _auth.currentUser?.reload();
                    if (_auth.currentUser?.emailVerified == true) {
                      _activateAndProceed();
                    } else {
                      _showSnack(
                        'Email not verified yet. Please check your inbox.',
                      );
                    }
                    setState(() => _isVerifying = false);
                  },
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _canResend ? _resendVerification : null,
                child: Text(
                  _canResend ? 'Resend Email' : 'Resend in ${_resendCooldown}s',
                  style: GoogleFonts.poppins(
                    color: _canResend ? AppColors.primary : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.poppins(color: Colors.black38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
