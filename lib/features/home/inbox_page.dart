import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/calls/view/call_history_tab.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/view/requests_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The inbox: friend requests and recent calls, chosen with a selector at the
/// top. Each section keeps its state while the other is shown.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

enum _InboxSection { requests, calls }

class _InboxPageState extends State<InboxPage> {
  _InboxSection _section = _InboxSection.requests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestCount = context.select(
      (ContactsCubit cubit) => cubit.state.requests.length,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ShadTabs<_InboxSection>(
            value: _section,
            onChanged: (section) => setState(() => _section = section),
            tabs: [
              ShadTab(
                key: const ValueKey('inbox-requests'),
                value: _InboxSection.requests,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.t('contacts.requests.title')),
                    if (requestCount > 0) ...[
                      const SizedBox(width: 6),
                      ShadBadge(child: Text('$requestCount')),
                    ],
                  ],
                ),
              ),
              ShadTab(
                key: const ValueKey('inbox-calls'),
                value: _InboxSection.calls,
                child: Text(l10n.t('calls.history.title')),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _section.index,
            children: const [RequestsList(), CallHistoryTab()],
          ),
        ),
      ],
    );
  }
}
