import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 600;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1200;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 1200;

  static double responsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? (mobile + desktop) / 2;
    return desktop;
  }

  static double textScaleFactor(BuildContext context, double baseSize) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    return textScale > 1.5 ? baseSize * 1.2 : baseSize;
  }
}