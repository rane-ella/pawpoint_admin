import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final String assetName;

  const AppLogo({
    super.key,
    this.width = 250,
    this.assetName = "assets/images/LOGO.png",
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetName, width: width, fit: BoxFit.contain);
  }
}
