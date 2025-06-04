import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const label = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

static const TextStyle bodyDark = TextStyle(color: Colors.white70, fontSize: 16);
static const TextStyle headingDark = TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold);
static const TextStyle labelDark = TextStyle(color: Colors.white70, fontSize: 14);

}
