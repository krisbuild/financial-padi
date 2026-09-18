import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';

const _themeModeKey = 'theme_mode';

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

/// The signed-in user's chosen currency. This is a per-account Firestore
/// value (set during onboarding, changeable in Settings), not a device
/// default, so it follows the user across devices and is never assumed.
final currencyCodeProvider = Provider<String>((ref) {
  final code = ref.watch(appUserProvider).value?.currencyCode;
  return (code == null || code.isEmpty) ? 'USD' : code;
});

Future<void> setUserCurrency(WidgetRef ref, String code) async {
  final uid = ref.read(currentFirebaseUserProvider)?.uid;
  if (uid == null) return;
  await ref.read(authServiceProvider).updateCurrency(uid: uid, currencyCode: code);
  ref.invalidate(appUserProvider);
}

const supportedCurrencies = <String, String>{
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'NGN': '₦',
  'KES': 'KSh',
  'GHS': 'GH₵',
  'ZAR': 'R',
  'INR': '₹',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'JPY': '¥',
  'CNY': '¥',
  'BRL': 'R\$',
  'MXN': 'MX\$',
  'PHP': '₱',
  'PKR': '₨',
  'IDR': 'Rp',
  'VND': '₫',
  'EGP': 'E£',
  'AED': 'د.إ',
};
