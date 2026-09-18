import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import 'firestore_provider.dart';

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchCategories();
});

final categoriesByTypeProvider =
    Provider.family<List<CategoryModel>, CategoryType>((ref, type) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories.where((c) => c.type == type).toList();
});

final categoryByIdProvider = Provider.family<CategoryModel?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
});
