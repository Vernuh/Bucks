import 'dart:async';

import 'package:bucks/screens/chat/chat_screen.dart';
import 'package:bucks/services/ai_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, dynamic>> sent;

  Widget app(Future<Map<String, dynamic>> Function(Map<String, dynamic>) send) {
    sent = [];
    final ai = AiService(
      transport: (body) {
        sent.add(body);
        return send(body);
      },
      hasSession: () => true,
    );
    return MaterialApp(home: ChatScreen(aiService: ai));
  }

  bool sendEnabled(WidgetTester t) =>
      t.widget<IconButton>(find.byKey(const Key('send_button'))).onPressed !=
      null;

  testWidgets('send is disabled for empty input and nothing is sent',
      (t) async {
    await t.pumpWidget(app((_) async => {'reply': 'x'}));
    expect(sendEnabled(t), isFalse);

    await t.enterText(find.byKey(const Key('chat_input')), '   ');
    await t.pump();
    expect(sendEnabled(t), isFalse);
    expect(sent, isEmpty);
  });

  testWidgets('shows question, loading state, then Bucks reply', (t) async {
    final c = Completer<Map<String, dynamic>>();
    await t.pumpWidget(app((_) => c.future));

    await t.enterText(find.byKey(const Key('chat_input')), 'How am I doing?');
    await t.pump();
    expect(sendEnabled(t), isTrue);
    await t.tap(find.byKey(const Key('send_button')));
    await t.pump();

    expect(find.text('How am I doing?'), findsOneWidget);
    expect(find.text('Bucks is thinking…'), findsOneWidget);
    expect(sendEnabled(t), isFalse); // protected while waiting

    c.complete({'reply': 'Nice work, you saved ₱500!'});
    await t.pumpAndSettle();

    expect(find.text('Nice work, you saved ₱500!'), findsOneWidget);
    expect(find.text('Bucks is thinking…'), findsNothing);
    expect(sent.length, 1);
  });

  testWidgets('shows a friendly error, and Try again resends', (t) async {
    var calls = 0;
    await t.pumpWidget(app((_) async {
      calls++;
      if (calls == 1) {
        throw const AiTransportException(status: 502, code: 'ai_unavailable');
      }
      return {'reply': 'Back online!'};
    }));

    await t.enterText(find.byKey(const Key('chat_input')), 'Hello');
    await t.pump();
    await t.tap(find.byKey(const Key('send_button')));
    await t.pumpAndSettle();

    expect(find.text(AiService.friendlyError), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();

    expect(find.text('Back online!'), findsOneWidget);
    expect(find.text(AiService.friendlyError), findsNothing);
    expect(find.text('Hello'), findsOneWidget); // not duplicated
    expect(calls, 2);
  });

  testWidgets('second question carries the earlier turns as history',
      (t) async {
    await t.pumpWidget(app((_) async => {'reply': 'ok'}));

    await t.enterText(find.byKey(const Key('chat_input')), 'first');
    await t.pump();
    await t.tap(find.byKey(const Key('send_button')));
    await t.pumpAndSettle();

    await t.enterText(find.byKey(const Key('chat_input')), 'second');
    await t.pump();
    await t.tap(find.byKey(const Key('send_button')));
    await t.pumpAndSettle();

    final history = sent.last['history'] as List;
    expect(history, [
      {'role': 'user', 'text': 'first'},
      {'role': 'model', 'text': 'ok'},
    ]);
  });

  testWidgets('tapping a suggestion asks that question', (t) async {
    await t.pumpWidget(app((_) async => {'reply': 'Looking good'}));
    await t.tap(find.text('Where am I spending the most?'));
    await t.pumpAndSettle();

    expect(sent.single['message'], 'Where am I spending the most?');
    expect(find.text('Looking good'), findsOneWidget);
  });
}
