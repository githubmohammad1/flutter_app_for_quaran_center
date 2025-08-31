import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

enum AppLocale { system, ar, en }

class SettingsController extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  AppLocale _locale = AppLocale.system;

  AppThemeMode get themeMode => _themeMode;
  AppLocale get locale => _locale;

Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  _themeMode = AppThemeMode.values[prefs.getInt('themeMode') ?? 0];
  _locale = AppLocale.values[prefs.getInt('locale') ?? 0];
  notifyListeners();
}
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      // ignore: unreachable_switch_default
      default:
        return ThemeMode.system;
    }
  }

  Locale? get materialLocale {
    switch (_locale) {
      case AppLocale.ar:
        return const Locale('ar');
      case AppLocale.en:
        return const Locale('en');
      case AppLocale.system:
      // ignore: unreachable_switch_default
      default:
        return null;
    }
  }

void setThemeMode(AppThemeMode mode) async {
  _themeMode = mode;
  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  prefs.setInt('themeMode', mode.index);
}

void setLocale(AppLocale loc) async {
  _locale = loc;
  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  prefs.setInt('locale', loc.index);
}
}
