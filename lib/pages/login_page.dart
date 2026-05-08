import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Core UI & Utility Imports
import '../core/widgets/app_text_field.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_logo.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/validators.dart';
import '../core/utils/error_handler.dart';
import '../services/admin_api_service.dart';
import 'verify_email_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // ── Header ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Center(child: AppLogo(width: 200)),
                    ],
                  ),
                ),

                // ── Login Fields ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 170),

                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            AppTextField(
                              controller: _emailController,
                              hint: "Email Address",
                              prefixIcon: Icons.email_outlined,
                              isRounded: true,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            // The Cat Position
                            Positioned(
                              top: -105,
                              child: IgnorePointer(
                                child: Image.asset(
                                  "assets/images/c1.png",
                                  width: 250,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox(height: 100),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        AppTextField(
                          controller: _passwordController,
                          hint: "Password",
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          isRounded: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black45,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 35),

                        AppButton(
                          text: "LOGIN",
                          isLoading: _isLoading,
                          onPressed: _handleAdminLogin,
                        ),

                        const SizedBox(height: 15),

                        // Portal Label
                        Text(
                          'ADMIN PORTAL',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 12,
                            color: Colors.black38,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdminLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    final passwordError = Validators.validateRequired(password, "Password");
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!adminDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _showError(
          'Unauthorized Access: This account has no admin privileges.',
        );
        return;
      }

      final data = adminDoc.data() as Map<String, dynamic>;
      final String role = data['role'] ?? '';
      final bool isActive = data['isActive'] ?? false;
      final bool isDeactivated = data['isDeactivated'] ?? false;

      if (isDeactivated) {
        await FirebaseAuth.instance.signOut();
        _showError('Access Denied: This account has been deactivated.');
        return;
      }

      if (credential.user != null && !credential.user!.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerifyAdminEmailPage(role: role)),
        );
        return;
      }

      if (!isActive) {
        try {
          await AdminApiService.markStaffActive(uid);
        } catch (e) {
          debugPrint('Activation failed: $e');
        }
      }

      if (!mounted) return;
      if (role == 'super_admin') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/super_admin',
          (_) => false,
        );
      } else if (role == 'staff_admin') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/staff_admin',
          (_) => false,
        );
      } else {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _showError(
          'Unauthorized Access: Unknown role assigned to this account.',
        );
      }
    } catch (e) {
      if (mounted) _showError(ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
