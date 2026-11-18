import 'dart:async';

import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/chat/data/chat_api.dart';
import 'package:amber_mobile_client/features/chat/data/chat_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConversationStatus { loading, loaded, failed }

class ConversationState {
  const ConversationState({
    this.status = ConversationStatus.loading,
    this.messages = const [],
    this.hasOlder = true,
    this.loadingOlder = false,
  });

  final ConversationStatus status;

  /// Oldest first, sorted by seq.
  final List<ChatMessage> messages;

  /// False once a page comes back shorter than the page size.
  final bool hasOlder;
  final bool loadingOlder;

  ConversationState copyWith({
    ConversationStatus? status,
    List<ChatMessage>? messages,
    bool? hasOlder,
    bool? loadingOlder,
  }) {
    return ConversationState(
      status: status ?? this.status,
      messages: messages == null ? this.messages : sortMessages(messages),
      hasOlder: hasOlder ?? this.hasOlder,
      loadingOlder: loadingOlder ?? this.loadingOlder,
    );
  }
}

/// Oldest first, with duplicates by id removed. The server sends the same
/// message both in an API response and as a `message.created` event.
List<ChatMessage> sortMessages(List<ChatMessage> messages) {
  final byId = {for (final m in messages) m.id: m};
  return byId.values.toList()..sort((a, b) => a.seq.compareTo(b.seq));
}

/// The messages of one direct conversation, kept live by realtime events for
/// that conversation only. Other conversations update through the contacts
/// list.
class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required this.conversationId,
    required this.myUserId,
    required this._api,
    Stream<Map<String, dynamic>> events = const Stream.empty(),
    this.pageSize = 20,
  }) : super(const ConversationState()) {
    _events = events.listen(_onEvent);
  }

  final String conversationId;
  final int myUserId;
  final int pageSize;
  final ChatApi _api;
  late final StreamSubscription<Map<String, dynamic>> _events;

  /// Loads the newest page. This also marks the conversation read.
  Future<void> load() async {
    emit(state.copyWith(status: ConversationStatus.loading));
    try {
      final page = await _api.messages(conversationId, limit: pageSize);
      emit(
        state.copyWith(
          status: ConversationStatus.loaded,
          messages: page,
          hasOlder: page.length == pageSize,
        ),
      );
    } on ApiFailure {
      emit(state.copyWith(status: ConversationStatus.failed));
    }
  }

  /// Loads the page before the oldest loaded message.
  Future<void> loadOlder() async {
    if (state.loadingOlder || !state.hasOlder || state.messages.isEmpty) {
      return;
    }
    emit(state.copyWith(loadingOlder: true));
    try {
      final before = state.messages.first.createdAt;
      final page = await _api.messages(
        conversationId,
        limit: pageSize,
        before: before,
      );
      emit(
        state.copyWith(
          messages: [...page, ...state.messages],
          hasOlder: page.length == pageSize,
          loadingOlder: false,
        ),
      );
    } on ApiFailure {
      emit(state.copyWith(loadingOlder: false));
      rethrow;
    }
  }

  /// Sends text. The message appears from the response, and the event
  /// that follows is ignored as a duplicate.
  Future<void> sendText(String text) async {
    final message = await _api.sendText(conversationId, text);
    _insert(message);
  }

  /// Marks everything up to the newest loaded message as read.
  Future<void> markRead() async {
    if (state.messages.isEmpty) return;
    final upto = state.messages.last.seq;
    await _api.markRead(conversationId, uptoSeq: upto);
  }

  Future<void> edit(ChatMessage message, String text) async {
    final updated = await _api.edit(
      conversationId,
      messageId: message.id,
      text: text,
    );
    _replace(updated);
  }

  Future<void> delete(ChatMessage message) async {
    await _api.delete(conversationId, messageId: message.id);
    _remove(message.id);
  }

  Future<void> react(ChatMessage message, String emoji) async {
    final mine = message.reactions.any(
      (r) => r.emoji == emoji && r.isReactedBy(myUserId),
    );
    final updated = mine
        ? await _api.removeReaction(
            conversationId,
            messageId: message.id,
            emoji: emoji,
          )
        : await _api.addReaction(
            conversationId,
            messageId: message.id,
            emoji: emoji,
          );
    _replace(updated);
  }

  void _onEvent(Map<String, dynamic> event) {
    if (isClosed || event['conversation_id'] != conversationId) return;
    final payload = event['payload'];
    if (payload is! Map<String, dynamic>) return;

    switch (event['event']) {
      case 'message.created':
        final message = payload['message'];
        if (message is Map<String, dynamic>) {
          _insert(ChatMessage.fromJson(message));
        }
      case 'message.edited' || 'message.reacted':
        final message = payload['message'];
        if (message is Map<String, dynamic>) {
          _replace(ChatMessage.fromJson(message));
        }
      case 'message.deleted':
        final id = payload['message_id'];
        if (id is String) _remove(id);
      case 'conversation.read_cursor.updated':
        _applyRead(payload);
    }
  }

  void _insert(ChatMessage message) {
    if (state.messages.any((m) => m.id == message.id)) return;
    emit(state.copyWith(messages: [...state.messages, message]));
  }

  void _replace(ChatMessage message) {
    emit(
      state.copyWith(
        messages: [
          for (final m in state.messages) m.id == message.id ? message : m,
        ],
      ),
    );
  }

  void _remove(String id) {
    emit(
      state.copyWith(
        messages: state.messages.where((m) => m.id != id).toList(),
      ),
    );
  }

  /// The other side read up to `last_seen_seq`. Only the current user's
  /// messages up to that seq become seen.
  void _applyRead(Map<String, dynamic> payload) {
    final readerId = payload['reader_id'];
    final lastSeenSeq = payload['last_seen_seq'];
    if (readerId is! int || lastSeenSeq is! int || readerId == myUserId) {
      return;
    }
    emit(
      state.copyWith(
        messages: [
          for (final m in state.messages)
            m.isMine(myUserId) && m.seq <= lastSeenSeq && !m.seen
                ? m.copyWith(seen: true)
                : m,
        ],
      ),
    );
  }

  @override
  Future<void> close() async {
    await _events.cancel();
    return super.close();
  }
}
