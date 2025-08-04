import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        // Light tema ayarlarınız
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        // Diğer light tema özellikleri
      );

  static ThemeData get dark => ThemeData(
        // Dark tema ayarlarınız
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        // Diğer dark tema özellikleri
      );
}
