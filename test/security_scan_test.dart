import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks that keep secrets out of the Flutter app and the repo, and
/// that the Edge Function only ever reads the signed-in user's own rows.
/// (Row Level Security itself can only be verified against a live Supabase
/// project; see README "Gemini AI Setup".)
void main() {
  List<File> filesIn(String dir, {Set<String> ext = const {}}) {
    final d = Directory(dir);
    if (!d.existsSync()) return [];
    return d
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => ext.isEmpty || ext.any(f.path.endsWith))
        .toList();
  }

  final clientFiles = [
    ...filesIn('lib', ext: {'.dart'}),
    ...filesIn('web'),
    ...filesIn('assets'),
    File('.env.example'),
    File('pubspec.yaml'),
  ].where((f) => f.existsSync()).toList();

  // Binary files (png, ico...) are scanned too; undecodable bytes are
  // tolerated instead of throwing.
  String read(File f) =>
      utf8.decode(f.readAsBytesSync(), allowMalformed: true);

  test('no Gemini/Google API key value appears in client files', () {
    final keyPattern = RegExp(r'AIza[0-9A-Za-z_\-]{30,}');
    for (final f in clientFiles) {
      expect(keyPattern.hasMatch(read(f)), isFalse, reason: f.path);
    }
  });

  test('Flutter code never references the Gemini key or Gemini endpoint', () {
    for (final f in clientFiles) {
      final text = read(f);
      expect(text.contains('GEMINI_API_KEY'), isFalse, reason: f.path);
      expect(text.contains('generativelanguage.googleapis.com'), isFalse,
          reason: f.path);
    }
  });

  test('no service-role / secret keys or JWTs in client or function code', () {
    final all = [
      ...clientFiles,
      ...filesIn('supabase/functions', ext: {'.ts'}),
    ];
    final bad = RegExp(
        r'service_role|SERVICE_ROLE|sb_secret_|eyJ[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{10,}');
    for (final f in all) {
      expect(bad.hasMatch(read(f)), isFalse, reason: f.path);
    }
  });

  test('.env is git-ignored and .env.example holds placeholders only', () {
    final ignore = File('.gitignore').readAsStringSync();
    expect(RegExp(r'^\.env\s*$', multiLine: true).hasMatch(ignore), isTrue);

    final example = File('.env.example').readAsStringSync();
    expect(example, contains('SUPABASE_URL=your_supabase_project_url'));
    expect(example, contains('SUPABASE_PUBLIC_KEY=your_supabase_public_key'));
    expect(example.contains('GEMINI'), isFalse);
  });

  test('Edge Function reads the key from secrets and only the caller\'s rows',
      () {
    final f = File('supabase/functions/bucks-ai/index.ts');
    expect(f.existsSync(), isTrue);
    final src = f.readAsStringSync();

    expect(src.contains('Deno.env.get("GEMINI_API_KEY")'), isTrue);
    // The user id comes from the verified token, never from the request body.
    expect(src.contains('const userId = auth.user.id'), isTrue);
    expect(src.contains('body.user'), isFalse);
    expect(src.contains('parsed.value.user'), isFalse);

    // Every query is filtered on the verified id (on top of RLS).
    final tableQueries = RegExp(r'db\.from\(').allMatches(src).length;
    final filtered = RegExp(r'\.eq\("(user_id|id)", userId\)')
        .allMatches(src)
        .length;
    expect(tableQueries, greaterThanOrEqualTo(7));
    expect(filtered, tableQueries);
  });
}
