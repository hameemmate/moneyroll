import 'package:flutter/material.dart';
import 'package:moneyrol/constants/app_constants.dart';

enum AppThemeType { blue, dark, green, orange, red, purple, white }

class AppThemeData {
  final Color primary;
  final Color income;
  final Color expense;
  final Color cardBackground;
  final Color iconBackground;
  final Color scaffoldBackground;
  final ThemeData themeData;

  AppThemeData({
    required this.primary,
    required this.income,
    required this.expense,
    required this.cardBackground,
    required this.iconBackground,
    required this.scaffoldBackground,
    required this.themeData,
  });
}

class AppThemes {
  // ---------------- Complete Theme Sets ----------------
  static AppThemeData getBlueTheme() {
    return AppThemeData(
      primary: AppConstants.primaryColor,
      income: AppConstants.incomeColor,
      expense: AppConstants.expenseColor,
      cardBackground: Colors.white,
      iconBackground: Colors.grey[200]!,
      scaffoldBackground: Colors.grey[50]!,
      themeData: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppConstants.primaryColor,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static AppThemeData getDarkTheme() {
    return AppThemeData(
      primary: Colors.blueAccent,
      income: Colors.greenAccent,
      expense: Colors.redAccent,
      cardBackground: Color(0xFF1E1E1E),
      iconBackground: Colors.grey[800]!,
      scaffoldBackground: Color(0xFF121212),
      themeData: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static AppThemeData getGreenTheme() {
    return AppThemeData(
      primary: AppConstants.incomeColor,
      income: AppConstants.incomeColor,
      expense: Color(0xFFC62828),
      cardBackground: Colors.white,
      iconBackground: Color(0xFFE8F5E9),
      scaffoldBackground: Color(0xFFF1F8E9),
      themeData: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppConstants.incomeColor,
        scaffoldBackgroundColor: Color(0xFFF1F8E9),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.incomeColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppConstants.incomeColor,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static AppThemeData getOrangeTheme() {
    return AppThemeData(
      primary: Colors.orange,
      income: Color(0xFF2E7D32),
      expense: Color(0xFFD32F2F),
      cardBackground: Colors.white,
      iconBackground: Color(0xFFFFF3E0),
      scaffoldBackground: Colors.orange[50]!,
      themeData: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.orange[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.orange,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static AppThemeData getRedTheme() {
    return AppThemeData(
      primary: Colors.red,
      income: Color(0xFF2E7D32),
      expense: Colors.red,
      cardBackground: Colors.white,
      iconBackground: Color(0xFFFFEBEE),
      scaffoldBackground: Colors.red[50]!,
      themeData: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.red[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.red,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static AppThemeData getPurpleTheme() {
    return AppThemeData(
      primary: Colors.purple,
      income: Color(0xFF2E7D32),
      expense: Color(0xFFD32F2F),
      cardBackground: Colors.white,
      iconBackground: Color(0xFFF3E5F5),
      scaffoldBackground: Colors.purple[50]!,
      themeData: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: Colors.purple[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.purple,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static AppThemeData getWhiteTheme() {
    return AppThemeData(
      primary: Colors.blue,
      income: Colors.green,
      expense: Colors.red,
      cardBackground: Colors.white,
      iconBackground: Colors.grey[100]!,
      scaffoldBackground: Colors.white,
      themeData: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ---------------- Helper Methods ----------------
  static AppThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.blue:
        return getBlueTheme();
      case AppThemeType.dark:
        return getDarkTheme();
      case AppThemeType.green:
        return getGreenTheme();
      case AppThemeType.orange:
        return getOrangeTheme();
      case AppThemeType.red:
        return getRedTheme();
      case AppThemeType.purple:
        return getPurpleTheme();
      case AppThemeType.white:
        return getWhiteTheme();
    }
  }

  static Color getThemeColor(AppThemeType type) => getTheme(type).primary;
  static Color getIncomeColor(AppThemeType type) => getTheme(type).income;
  static Color getExpenseColor(AppThemeType type) => getTheme(type).expense;
  static Color getCardColor(AppThemeType type) => getTheme(type).cardBackground;
  static Color getIconBackgroundColor(AppThemeType type) =>
      getTheme(type).iconBackground;
  static Color getBackgroundColor(AppThemeType type) =>
      getTheme(type).scaffoldBackground;
  static ThemeData getThemeData(AppThemeType type) => getTheme(type).themeData;
}
