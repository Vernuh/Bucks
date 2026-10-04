/// Central place for build-time configuration.

class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublicKey =
      String.fromEnvironment('SUPABASE_PUBLIC_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabasePublicKey.isNotEmpty &&
      !supabaseUrl.startsWith('your_') &&
      !supabasePublicKey.startsWith('your_');

  /// Throws a clear development error instead of silently using fake values.
  static void ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Copy .env.example to .env, fill in '
        'SUPABASE_URL and SUPABASE_PUBLIC_KEY, then run:\n'
        '  flutter run -d chrome --dart-define-from-file=.env',
      );
    }
  }
}
