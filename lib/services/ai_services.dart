import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One earlier message sent along so Bucks can follow the conversation.
class AiTurn {
  final bool fromUser;
  final String text;
  const AiTurn({required this.fromUser, required this.text});
}

/// A problem that can be shown to the user as-is. [message] is always
/// friendly and never contains technical details, keys or tokens.
class AiException implements Exception {
  final String message;

  /// True when the user has to log in again.
  final bool sessionExpired;
  const AiException(this.message, {this.sessionExpired = false});

  @override
  String toString() => message;
}

class AiTransportException implements Exception {
  final int? status;
  final String? code;
  const AiTransportException({this.status, this.code});
}

/// Sends the request body to the Edge Function and returns its JSON.
typedef AiTransport = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> body);

/// Talks to Gemini ONLY through the `bucks-ai` Supabase Edge Function:
///
///   ChatScreen -> AiService -> Edge Function -> Gemini

class AiService {
  AiService({
    AiTransport? transport,
    bool Function()? hasSession,
    this.timeout = const Duration(seconds: 35),
  })  : _transport = transport ?? _invokeEdgeFunction,
        _hasSession = hasSession ?? _supabaseHasSession;

  static const String functionName = 'bucks-ai';
  static const int maxQuestionChars = 500;
  static const int maxHistoryTurns = 6;

  static const String friendlyError =
      "Bucks couldn't reach his AI brain right now. Please try again.";

  final AiTransport _transport;
  final bool Function() _hasSession;
  /// How long to wait for Bucks before giving up.
  final Duration timeout;

  Future<String> askBucksAssistant(
    String question, {
    List<AiTurn> history = const [],
  }) async {
    final text = question.trim();
    if (text.isEmpty) {
      throw const AiException('Type a question for Bucks first.');
    }
    if (text.length > maxQuestionChars) {
      throw const AiException(
          'Please keep your question under $maxQuestionChars characters.');
    }
    if (!_hasSession()) {
      throw const AiException('Please log in to chat with Bucks.',
          sessionExpired: true);
    }

    final recent = history.length > maxHistoryTurns
        ? history.sublist(history.length - maxHistoryTurns)
        : history;

    final body = <String, dynamic>{
      'message': text,
      'history': [
        for (final t in recent)
          {'role': t.fromUser ? 'user' : 'model', 'text': t.text},
      ],
      // Lets the server work out "this month" in the user's own time zone.
      'utc_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
    };

    try {
      final data = await _transport(body).timeout(timeout);
      final reply = data['reply'];
      if (reply is! String || reply.trim().isEmpty) {
        _log('empty or malformed reply');
        throw const AiException(friendlyError);
      }
      return reply.trim();
    } on AiException {
      rethrow;
    } on AiTransportException catch (e) {
      _log('server error status=${e.status} code=${e.code}');
      throw _mapTransportError(e);
    } on TimeoutException {
      _log('timeout');
      throw const AiException(
          'Bucks is taking too long to answer. Please try again.');
    } catch (e) {
      _log('request failed: ${e.runtimeType}');
      if (_looksLikeNetworkProblem(e)) {
        throw const AiException(
            "Can't reach the internet. Check your connection and try again.");
      }
      throw const AiException(friendlyError);
    }
  }

  AiException _mapTransportError(AiTransportException e) {
    if (e.status == 401 || e.code == 'unauthenticated') {
      return const AiException('Your session expired. Please log in again.',
          sessionExpired: true);
    }
    if (e.status == 429 ||
        e.code == 'rate_limited' ||
        e.code == 'ai_rate_limited') {
      return const AiException(
          'Bucks needs a short break. Please try again in a minute.');
    }
    if (e.code == 'message_too_long') {
      return const AiException(
          'Please keep your question under $maxQuestionChars characters.');
    }
    return const AiException(friendlyError);
  }

  bool _looksLikeNetworkProblem(Object e) {
    final s = e.toString();
    return s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('XMLHttpRequest') ||
        s.contains('Failed host lookup');
  }

  /// Development logging: status codes and error types only. Never the
  /// question, the reply, tokens or financial data.
  void _log(String what) => debugPrint('AiService: $what');

  // --- real network transport ---------------------------------------------

  static bool _supabaseHasSession() =>
      Supabase.instance.client.auth.currentSession != null;

  static Future<Map<String, dynamic>> _invokeEdgeFunction(
      Map<String, dynamic> body) async {
    try {
      final res = await Supabase.instance.client.functions
          .invoke(functionName, body: body);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      throw const AiTransportException();
    } on FunctionException catch (e) {
      final details = e.details;
      throw AiTransportException(
        status: e.status,
        code: details is Map ? details['error']?.toString() : null,
      );
    }
  }
}