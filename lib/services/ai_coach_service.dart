import '../models/financial_snapshot.dart';

/// The contract the rest of the app talks to. [MockAiCoachService] answers
/// with rule-based, data-driven text so the coach feels useful today; a
/// real implementation (e.g. calling Claude through a backend that holds
/// the API key — never embedded in the client) can replace it later
/// without touching any UI or provider code.
abstract class AiCoachService {
  Future<String> ask(String question, FinancialSnapshot snapshot);

  /// A handful of short, standalone observations about the snapshot,
  /// freshest/most relevant first. The UI picks one for the home card and
  /// can show the rest in the coach chat as suggested starters.
  List<String> insights(FinancialSnapshot snapshot);
}
