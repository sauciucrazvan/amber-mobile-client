import 'dart:async';

import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/realtime/realtime_client.dart';
import 'package:amber_mobile_client/features/home/realtime_status_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets(
    'shows a progress bar while connecting, and an error when it fails',
    (tester) async {
      final localizations = (await tester.runAsync(
        () => AppLocalizations.load('en'),
      ))!;
      final states = StreamController<RealtimeConnectionState>.broadcast();
      addTearDown(states.close);

      await tester.pumpWidget(
        AppLocalizationsScope(
          localizations: localizations,
          child: ShadApp.custom(
            appBuilder: (_) => MaterialApp(
              // The app adds the toaster in MaterialApp's builder.
              builder: (context, child) => ShadToaster(child: child!),
              home: Scaffold(
                body: Column(
                  children: [RealtimeStatusBar(states: states.stream)],
                ),
              ),
            ),
          ),
        ),
      );

      states.add(RealtimeConnectionState.connecting);
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      states.add(RealtimeConnectionState.connected);
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);

      states.add(RealtimeConnectionState.failed);
      await tester.pump();
      expect(
        find.text('Connection to the selected server failed.'),
        findsOneWidget,
      );
    },
  );
}
