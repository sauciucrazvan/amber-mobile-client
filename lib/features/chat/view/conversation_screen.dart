import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/chat/bloc/conversation_cubit.dart';
import 'package:amber_mobile_client/features/chat/data/chat_api.dart';
import 'package:amber_mobile_client/features/chat/data/chat_models.dart';
import 'package:amber_mobile_client/features/chat/view/message_bubble.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/view/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Opens the direct chat with [contact]. [contactsCubit] is passed on so the
/// header can open the contact's profile.
Future<void> showConversation(
  BuildContext context,
  ContactUser contact,
  ContactsCubit contactsCubit,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: contactsCubit,
        child: ConversationScreen(contact: contact),
      ),
    ),
  );
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.contact});

  final ContactUser contact;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  Conversation? _conversation;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final api = ChatApi(context.read<AppServices>().apiClient);
    try {
      final conversation = await api.openDirect(widget.contact.id);
      if (mounted) setState(() => _conversation = conversation);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _errorKey = failure.messageKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conversation = _conversation;
    final errorKey = _errorKey;

    if (conversation == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.contact.displayName)),
        body: Center(
          child: errorKey == null
              ? const SizedBox(width: 160, child: ShadProgress())
              : Text(l10n.t(errorKey)),
        ),
      );
    }

    final services = context.read<AppServices>();
    final myUserId = context.read<AuthCubit>().state.account?.id ?? -1;
    return BlocProvider(
      create: (_) => ConversationCubit(
        conversationId: conversation.id,
        myUserId: myUserId,
        api: ChatApi(services.apiClient),
        events: services.realtimeEvents,
      )..load(),
      child: _ConversationBody(contact: widget.contact, myUserId: myUserId),
    );
  }
}

class _ConversationBody extends StatefulWidget {
  const _ConversationBody({required this.contact, required this.myUserId});

  final ContactUser contact;
  final int myUserId;

  @override
  State<_ConversationBody> createState() => _ConversationBodyState();
}

class _ConversationBodyState extends State<_ConversationBody> {
  final _scroll = ScrollController();
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadOlder);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  /// The list is reversed (newest at the bottom), so the older end is the
  /// maximum scroll extent.
  void _maybeLoadOlder() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 200) {
      return;
    }
    context.read<ConversationCubit>().loadOlder().catchError((_) {});
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await context.read<ConversationCubit>().sendText(text);
      if (mounted) _text.clear();
    } on ApiFailure catch (failure) {
      if (mounted) _showError(failure.messageKey);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String key) {
    ShadToaster.of(context).show(
      ShadToast.destructive(
        description: Text(AppLocalizations.of(context).t(key)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final contact = widget.contact;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => showContactProfile(
            context,
            contact.username,
            context.read<ContactsCubit>(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(contact.displayName),
              Text(
                contact.online
                    ? l10n.t('common.online')
                    : contact.lastActiveAt == null
                    ? ''
                    : formatDay(dayOf(contact.lastActiveAt)),
                style: theme.textTheme.small,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<ConversationCubit, ConversationState>(
                listenWhen: (previous, current) =>
                    _lastSeq(previous) != _lastSeq(current),
                listener: (context, _) {
                  context.read<ConversationCubit>().markRead().catchError(
                    (_) {},
                  );
                },
                builder: (context, state) => _MessageList(
                  state: state,
                  myUserId: widget.myUserId,
                  controller: _scroll,
                ),
              ),
            ),
            _Composer(controller: _text, sending: _sending, onSend: _send),
          ],
        ),
      ),
    );
  }

  int? _lastSeq(ConversationState state) =>
      state.messages.isEmpty ? null : state.messages.last.seq;
}

/// Messages newest at the bottom, with a divider above each day's first
/// message and a spinner while older messages load.
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.state,
    required this.myUserId,
    required this.controller,
  });

  final ConversationState state;
  final int myUserId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.status == ConversationStatus.failed) {
      return Center(child: Text(l10n.t('conversations.error.failed_loading')));
    }
    if (state.status == ConversationStatus.loading && state.messages.isEmpty) {
      return const Center(child: SizedBox(width: 160, child: ShadProgress()));
    }

    final items = _items(state.messages);
    return ListView.builder(
      reverse: true,
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length + (state.loadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: ShadProgress()),
          );
        }
        final item = items[index];
        if (item is DateTime) return DaySeparator(day: item);
        final message = item as ChatMessage;
        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMine: message.isMine(myUserId),
        );
      },
    );
  }

  /// Newest first, for a reversed list. Each day's divider follows its
  /// oldest message, so it appears above that day's messages.
  List<Object> _items(List<ChatMessage> messages) {
    final items = <Object>[];
    for (var i = messages.length - 1; i >= 0; i--) {
      items.add(messages[i]);
      final isFirstOfDay =
          i == 0 ||
          dayOf(messages[i - 1].createdAt) != dayOf(messages[i].createdAt);
      if (isFirstOfDay) items.add(dayOf(messages[i].createdAt));
    }
    return items;
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: ShadInput(
              controller: controller,
              placeholder: Text(l10n.t('conversations.type_message')),
              textInputAction: TextInputAction.send,
              enabled: !sending,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          ShadIconButton(
            key: const ValueKey('send-message'),
            icon: const Icon(LucideIcons.send),
            onPressed: sending ? null : onSend,
          ),
        ],
      ),
    );
  }
}
