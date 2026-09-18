import 'package:intl/intl.dart';

import '../../providers/settings_provider.dart';

String formatCurrency(double amount, String currencyCode) {
  final symbol = supportedCurrencies[currencyCode] ?? currencyCode;
  final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
  return formatter.format(amount);
}

String formatCompactCurrency(double amount, String currencyCode) {
  final symbol = supportedCurrencies[currencyCode] ?? currencyCode;
  final formatter = NumberFormat.compactCurrency(symbol: symbol);
  return formatter.format(amount);
}
