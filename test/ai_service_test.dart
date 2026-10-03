import 'dart:async';

import 'package:bucks/services/ai_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, dynamic>> sent;

  AiService service({
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>) send,
    bool signedIn = true,
    Duration timeout = const Duration(seconds: 5),
  }) {
    sent = [];
    return AiService(
      transport: (body) {
        sent.add(body);
        return send(body);
      },
      hasSession: () => signedIn,
      timeout: timeout,
    );
  }

  Future<AiException> failure(AiService s, [String q = 'hi']) async {
    try {
      await s.askBucksAssistant(q);
    } on AiException catch (e) {
      return e;
    }
    fail('expected an AiException');
  }

  test('calls the Edge Function transport with the trimmed question', () async {
    final s = service(send: (_) async => {'reply': '  You are doing great!  '});
    final reply = await s.askBucksAssistant('  How am I doing?  ');

    expect(reply, 'You are doing great!');
    expect(sent.single['message'], 'How am I doing?');
    expect(sent.single['utc_offset_minutes'], isA<int>());
    expect(sent.single['history'], isEmpty);
  });

  test('sends only financial data the server needs: no figures from the client',
      () async {
    final s = service(send: (_) async => {'reply': 'ok'});
    await s.askBucksAssistant('How am I doing?');
    expect(sent.single.keys.toSet(),
        {'message', 'history', 'utc_offset_minutes'});
  });

  test('rejects empty and blank questions without calling the server', () async {
    final s = service(send: (_) async => {'reply': 'x'});
    expect((await failure(s, '')).message, contains('Type a question'));
    expect((await failure(s, '   ')).message, contains('Type a question'));
    expect(sent, isEmpty);
  });

  test('rejects over-long questions without calling the server', () async {
    final s = service(send: (_) async => {'reply': 'x'});
    final e = await failure(s, 'a' * (AiService.maxQuestionChars + 1));
    expect(e.message, contains('under'));
    expect(sent, isEmpty);
  });

  test('signed-out users cannot use the AI and nothing is sent', () async {
    final s = service(send: (_) async => {'reply': 'x'}, signedIn: false);
    final e = await failure(s);
    expect(e.sessionExpired, isTrue);
    expect(sent, isEmpty);
  });

  test('sends at most the last 6 turns as history, with model/user roles',
      () async {
    final s = service(send: (_) async => {'reply': 'ok'});
    final history = [
      for (var i = 0; i < 10; i++) AiTurn(fromUser: i.isEven, text: 't$i'),
    ];
    await s.askBucksAssistant('next', history: history);

    final sentHistory = sent.single['history'] as List;
    expect(sentHistory.length, 6);
    expect(sentHistory.first, {'role': 'user', 'text': 't4'});
    expect(sentHistory.last, {'role': 'model', 'text': 't9'});
  });

  test('401 from the server means session expired', () async {
    final s = service(
        send: (_) async => throw const AiTransportException(status: 401));
    final e = await failure(s);
    expect(e.sessionExpired, isTrue);
    expect(e.message, contains('log in again'));
  });

  test('429 is shown as a short-break message', () async {
    final s = service(
        send: (_) async => throw const AiTransportException(status: 429));
    expect((await failure(s)).message, contains('short break'));
  });

  test('Gemini/server failures show the friendly message, no internals',
      () async {
    final s = service(
        send: (_) async => throw const AiTransportException(
            status: 502, code: 'ai_unavailable'));
    final e = await failure(s);
    expect(e.message, AiService.friendlyError);
    expect(e.message.toLowerCase(), isNot(contains('gemini')));
    expect(e.message, isNot(contains('502')));
  });

  test('empty, missing or malformed replies are handled', () async {
    for (final data in [
      <String, dynamic>{},
      {'reply': ''},
      {'reply': '   '},
      {'reply': 42},
      {'something': 'else'},
    ]) {
      final s = service(send: (_) async => data);
      expect((await failure(s)).message, AiService.friendlyError,
          reason: '$data');
    }
  });

  test('unexpected exceptions never leak their text to the user', () async {
    final s = service(send: (_) async => throw StateError('secret detail'));
    final e = await failure(s);
    expect(e.message, AiService.friendlyError);
    expect(e.message, isNot(contains('secret detail')));
  });

  test('network problems get a connection message', () async {
    final s = service(
        send: (_) async => throw Exception('ClientException: Failed to fetch'));
    expect((await failure(s)).message, contains('internet'));
  });

  test('timeouts get a friendly message', () async {
    final s = service(
      send: (_) => Completer<Map<String, dynamic>>().future, // never completes
      timeout: const Duration(milliseconds: 20),
    );
    expect((await failure(s)).message, contains('too long'));
  });
}
