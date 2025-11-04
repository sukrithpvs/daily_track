import 'package:flutter/material.dart';

class ResponsiveUtils {
  /// Check if the device is a tablet (width > 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  /// Check if the device is a phone (width <= 600)
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width <= 600;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    }
    return const EdgeInsets.all(16.0);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isTablet(context)) {
      return baseFontSize * 1.2;
    }
    return baseFontSize;
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isTablet(context)) {
      return baseSpacing * 1.5;
    }
    return baseSpacing;
  }

  /// Get responsive card width for tablets
  static double? getCardWidth(BuildContext context) {
    if (isTablet(context)) {
      final screenWidth = MediaQuery.of(context).size.width;
      return screenWidth * 0.8; // 80% of screen width on tablets
    }
    return null; // Full width on phones
  }

  /// Get responsive column count for grid layouts
  static int getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    if (isTablet(context)) {
      return 56.0;
    }
    return 48.0;
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    if (isTablet(context)) {
      return baseSize * 1.3;
    }
    return baseSize;
  }
}

/// Extension to make responsive utilities easier to use
extension ResponsiveContext on BuildContext {
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isPhone => ResponsiveUtils.isPhone(this);
  
  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);
  double get responsiveButtonHeight => ResponsiveUtils.getButtonHeight(this);
  double? get cardWidth => ResponsiveUtils.getCardWidth(this);
  
  double responsiveFontSize(double baseSize) => 
      ResponsiveUtils.getResponsiveFontSize(this, baseSize);
      
  double responsiveSpacing(double baseSpacing) => 
      ResponsiveUtils.getResponsiveSpacing(this, baseSpacing);
      
  double responsiveIconSize(double baseSize) => 
      ResponsiveUtils.getIconSize(this, baseSize);
}