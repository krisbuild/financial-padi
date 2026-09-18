import 'package:flutter/material.dart';

/// A fixed registry of icons category models can reference by string key.
/// Using literal [IconData] constants here (rather than codepoints decoded
/// at runtime) keeps Flutter's release-build icon tree-shaking working.
const Map<String, IconData> categoryIcons = {
  'payments': Icons.payments,
  'storefront': Icons.storefront,
  'card_giftcard': Icons.card_giftcard,
  'attach_money': Icons.attach_money,
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'shopping_bag': Icons.shopping_bag,
  'receipt_long': Icons.receipt_long,
  'local_hospital': Icons.local_hospital,
  'movie': Icons.movie,
  'school': Icons.school,
  'home': Icons.home,
  'more_horiz': Icons.more_horiz,
  'category': Icons.category,
  'flag': Icons.flag,
  'fitness_center': Icons.fitness_center,
  'pets': Icons.pets,
  'flight': Icons.flight,
  'phone_iphone': Icons.phone_iphone,
  'child_care': Icons.child_care,
};

IconData iconForKey(String key) => categoryIcons[key] ?? Icons.category;
