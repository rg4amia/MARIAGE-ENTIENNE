import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

String venueLabel(String type) {
  return switch (type) {
    'town_hall' => 'MAIRIE',
    'church' => 'ÉGLISE / CULTE',
    'reception' => 'RÉCEPTION',
    _ => 'AUTRE LIEU',
  };
}

IconData venueIcon(String type) {
  return switch (type) {
    'town_hall' => Icons.account_balance_rounded,
    'church' => Icons.church_rounded,
    'reception' => Icons.celebration_rounded,
    _ => Icons.place_rounded,
  };
}

Color venueColor(String type) {
  return switch (type) {
    'town_hall' => AppColors.primary,
    'church' => AppColors.tertiary,
    'reception' => AppColors.secondary,
    _ => AppColors.dark,
  };
}
