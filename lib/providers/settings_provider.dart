import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';
const _currencyCodeKey = 'currency_code';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey);
    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class CurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'USD';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_currencyCodeKey);
    if (saved != null) state = saved;
  }

  Future<void> setCurrency(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, code);
  }
}

final currencyCodeProvider = NotifierProvider<CurrencyNotifier, String>(
  CurrencyNotifier.new,
);

const supportedCurrencies = <String, String>{
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'NGN': '₦',
  'KES': 'KSh',
  'GHS': 'GH₵',
  'ZAR': 'R',
  'INR': '₹',
};
