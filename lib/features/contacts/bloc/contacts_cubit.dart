import 'dart:async';

import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ContactsStatus { loading, loaded, failed }

class ContactsState {
  const ContactsState({
    this.status = ContactsStatus.loading,
    this.contacts = const [],
    this.requests = const [],
  });

  final ContactsStatus status;

  /// Most recent activity first.
  final List<Contact> contacts;
  final List<ContactRequest> requests;

  ContactsState copyWith({
    ContactsStatus? status,
    List<Contact>? contacts,
    List<ContactRequest>? requests,
  }) {
    return ContactsState(
      status: status ?? this.status,
      contacts: contacts == null ? this.contacts : sortContacts(contacts),
      requests: requests ?? this.requests,
    );
  }
}

/// Sorts by last action, newest first, then by username, as the backend does.
List<Contact> sortContacts(List<Contact> contacts) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return [...contacts]..sort((a, b) {
    final byTime = (b.lastActionAt ?? epoch).compareTo(a.lastActionAt ?? epoch);
    return byTime != 0 ? byTime : a.user.username.compareTo(b.user.username);
  });
}

/// Contacts and incoming requests, kept live by realtime events instead of
/// refetching.
class ContactsCubit extends Cubit<ContactsState> {
  ContactsCubit({
    required this._api,
    Stream<Map<String, dynamic>> events = const Stream.empty(),
  }) : super(const ContactsState()) {
    _events = events.listen(_onEvent);
  }

  final ContactsApi _api;
  late final StreamSubscription<Map<String, dynamic>> _events;

  Future<void> load() async {
    emit(state.copyWith(status: ContactsStatus.loading));
    try {
      final (contacts, requests) = await (_api.list(), _api.requests()).wait;
      emit(
        state.copyWith(
          status: ContactsStatus.loaded,
          contacts: contacts,
          requests: requests,
        ),
      );
    } on ParallelWaitError<dynamic, dynamic> {
      emit(state.copyWith(status: ContactsStatus.failed));
    }
  }

  /// Throws [ApiFailure] so the add-contact dialog can show the message.
  Future<void> sendRequest(String identifier) => _api.sendRequest(identifier);

  Future<void> accept(ContactRequest request) async {
    await _api.accept(request.user.username);
    _upsertContact(
      Contact(user: request.user, lastActionAt: DateTime.now().toUtc()),
    );
  }

  Future<void> decline(ContactRequest request) async {
    await _api.decline(request.user.username);
    _removeRequest(request.user.id);
  }

  Future<void> remove(ContactUser user) async {
    await _api.remove(user.username);
    _removeContact(user.id);
  }

  /// Blocking also removes the contact and any pending request.
  Future<void> block(ContactUser user) async {
    await _api.block(user.username);
    _removeContact(user.id);
    _removeRequest(user.id);
  }

  void _onEvent(Map<String, dynamic> event) {
    if (isClosed) return;
    final name = event['event'];

    if (event['type'] == 'presence' && event['username'] is String) {
      final online = name == 'user_connected';
      _updateUser(
        (user) => user.username == event['username'],
        (user) => user.copyWith(
          online: online,
          lastActiveAt: online ? null : DateTime.now().toUtc(),
        ),
      );
      return;
    }

    final payload = event['payload'];
    if (event['type'] != 'contacts' || payload is! Map<String, dynamic>) {
      return;
    }
    final user = payload['user'];
    final userId = payload['user_id'];

    switch (name) {
      case 'contact.request.received' when user is Map<String, dynamic>:
        final request = ContactRequest.fromJson(payload);
        emit(
          state.copyWith(
            requests: [
              request,
              ...state.requests.where((r) => r.user.id != request.user.id),
            ],
          ),
        );
      case 'contact.request.removed' when userId is int:
        _removeRequest(userId);
      case 'contact.accepted' when user is Map<String, dynamic>:
        _upsertContact(Contact.fromJson(payload));
      case 'contact.removed':
        for (final id in [userId, payload['other_user_id']]) {
          if (id is int) _removeContact(id);
        }
      case 'contact.profile.updated' when user is Map<String, dynamic>:
        final updated = ContactUser.fromJson(user);
        _updateUser(
          (existing) => existing.id == updated.id,
          (existing) => existing.copyWith(
            fullName: updated.fullName,
            avatarUrl: updated.avatarUrl,
            online: updated.online,
            lastActiveAt: updated.lastActiveAt,
          ),
        );
      case 'contact.last_action.updated' when userId is int:
        final at = parseServerTime(payload['last_action_at']);
        if (at == null) return;
        _updateContact(userId, (contact) => contact.copyWith(lastActionAt: at));
      case 'contact.last_message.updated' when userId is int:
        final message = payload['last_message'];
        _updateContact(
          userId,
          (contact) => message is Map<String, dynamic>
              ? contact.copyWith(lastMessage: LastMessage.fromJson(message))
              : contact.copyWith(clearLastMessage: true),
        );
    }
  }

  void _upsertContact(Contact contact) {
    emit(
      state.copyWith(
        contacts: [
          ...state.contacts.where((c) => c.user.id != contact.user.id),
          contact,
        ],
        requests: state.requests
            .where((r) => r.user.id != contact.user.id)
            .toList(),
      ),
    );
  }

  void _removeContact(int userId) {
    emit(
      state.copyWith(
        contacts: state.contacts.where((c) => c.user.id != userId).toList(),
      ),
    );
  }

  void _removeRequest(int userId) {
    emit(
      state.copyWith(
        requests: state.requests.where((r) => r.user.id != userId).toList(),
      ),
    );
  }

  void _updateContact(int userId, Contact Function(Contact) update) {
    emit(
      state.copyWith(
        contacts: [
          for (final c in state.contacts) c.user.id == userId ? update(c) : c,
        ],
      ),
    );
  }

  void _updateUser(
    bool Function(ContactUser) matches,
    ContactUser Function(ContactUser) update,
  ) {
    emit(
      state.copyWith(
        contacts: [
          for (final c in state.contacts)
            matches(c.user) ? c.copyWith(user: update(c.user)) : c,
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
