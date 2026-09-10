import 'package:flutter/material.dart';

/// Colores semánticos que no dependen del brillo del tema (estrella de rating y
/// corazón de favorito mantienen su significado en light y dark).
class AppColors {
  AppColors._();

  static const Color rating = Color(0xFFFFB300);
  static const Color favorite = Color(0xFFE53935);
}
