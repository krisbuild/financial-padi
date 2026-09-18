import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal_model.dart';
import 'firestore_provider.dart';

final goalsProvider = StreamProvider<List<GoalModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchGoals();
});
