import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.grey[100],
      primaryColor: const Color(0xFFd32f2f),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFd32f2f),
        onPrimary: Colors.white,
        secondary: Colors.grey[700]!,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
        background: Colors.grey[100]!,
        onBackground: Colors.black87,
        error: Colors.red[800]!,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: 1.2,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme()
          .apply(
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          )
          .copyWith(
            bodyLarge:
                GoogleFonts.poppins(fontSize: 16.sp, color: Colors.black87),
            bodyMedium:
                GoogleFonts.poppins(fontSize: 14.sp, color: Colors.black54),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFd32f2f),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          elevation: 5,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            letterSpacing: 1.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[200],
        labelStyle: GoogleFonts.poppins(color: Colors.black87),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFd32f2f),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      cardColor: const Color(0xFF2C2C2C),
      canvasColor: const Color(0xFF2C2C2C),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFd32f2f),
        onPrimary: Colors.white,
        secondary: const Color(0xFFd32f2f),
        onSecondary: Colors.white,
        surface: const Color(0xFF2C2C2C),
        onSurface: Colors.white70,
        background: const Color(0xFF1A1A1A),
        onBackground: Colors.white,
        error: Colors.red[800]!,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme()
          .apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          )
          .copyWith(
            bodyLarge:
                GoogleFonts.poppins(fontSize: 16.sp, color: Colors.white),
            bodyMedium:
                GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white70),
            bodySmall:
                GoogleFonts.poppins(fontSize: 12.sp, color: Colors.white54),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFd32f2f),
          foregroundColor: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFd32f2f),
          side: const BorderSide(color: Color(0xFFd32f2f), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          textStyle:
              GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2C2C2C),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        hintStyle: GoogleFonts.poppins(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFd32f2f), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1.w),
        ),
        prefixIconColor: Colors.white70,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedItemColor: const Color(0xFFd32f2f),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11.sp),
      ),
    );
  }
}
