/// Central place for build-time configuration.
///
/// Values are injected with `--dart-define-from-file=.env` (see README), so
/// no credentials live in source code and nothing extra is bundled as an
/// asset. Only the PUBLIC Supabase key is ever used here; data security is
/// enforced by Supabase Auth + Row Level Security, not by hiding this key.
///
/// NEVER add a service-role key, database password or AI secret to the app.
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
