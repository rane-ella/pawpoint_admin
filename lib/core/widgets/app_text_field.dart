import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;
  final bool isRounded;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.helperText,
    this.isRounded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isRounded ? 16 : 50),
        border: !isRounded ? Border.all(color: Colors.black) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          helperText: helperText,
          hintStyle: AppTextStyles.hint,
          helperStyle: AppTextStyles.hint.copyWith(fontSize: 11),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 20, color: AppColors.grey)
              : null,
          suffixIcon: suffixIcon,
          border: isRounded
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(55),
                  borderSide: const BorderSide(color: Colors.black),
                ),
          enabledBorder: isRounded
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(55),
                  borderSide: const BorderSide(color: Colors.black),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
