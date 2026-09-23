/// Placeholder for the future AI Budgeting Assistant.
///
/// IMPORTANT: When this is implemented, the API key must NOT be
/// hard-coded here. It should come from an environment/config value,
/// e.g. passed in at build time with:
///
///   flutter run --dart-define=AI_API_KEY=your_key_here
///
/// and read with:
///
///   const apiKey = String.fromEnvironment('AI_API_KEY');
///
/// We are not implementing real calls yet — this class exists so the
/// rest of the app can be written against a stable method signature.
class AiService {
  Future<String> askBucksAssistant(String question) async {
    // TODO: replace with a real API call once the AI feature is built.
    return "Bucks' AI assistant isn't hooked up yet — coming soon!";
  }
}