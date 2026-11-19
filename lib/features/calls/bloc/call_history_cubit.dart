import 'package:amber_mobile_client/features/calls/data/call_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CallHistoryStatus { loading, ready, failed }

class CallHistoryState {
  const CallHistoryState({
    this.status = CallHistoryStatus.loading,
    this.entries = const [],
    this.total = 0,
    this.loadingMore = false,
  });

  final CallHistoryStatus status;
  final List<CallHistoryEntry> entries;
  final int total;
  final bool loadingMore;

  bool get hasMore => entries.length < total;
}

/// The call history, newest first. Loads one page, and more as the list
/// scrolls. A refresh starts again from the first page.
class CallHistoryCubit extends Cubit<CallHistoryState> {
  CallHistoryCubit({required this.api}) : super(const CallHistoryState());

  static const pageSize = 50;

  final CallHistoryApi api;

  Future<void> load() async {
    try {
      final page = await api.page(offset: 0, limit: pageSize);
      if (isClosed) return;
      emit(
        CallHistoryState(
          status: CallHistoryStatus.ready,
          entries: page.entries,
          total: page.total,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        CallHistoryState(
          status: CallHistoryStatus.failed,
          entries: state.entries,
          total: state.total,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status != CallHistoryStatus.ready ||
        state.loadingMore ||
        !state.hasMore) {
      return;
    }
    final offset = state.entries.length;
    emit(
      CallHistoryState(
        status: state.status,
        entries: state.entries,
        total: state.total,
        loadingMore: true,
      ),
    );
    try {
      final page = await api.page(offset: offset, limit: pageSize);
      if (isClosed) return;
      emit(
        CallHistoryState(
          status: CallHistoryStatus.ready,
          entries: [...state.entries, ...page.entries],
          total: page.total,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        CallHistoryState(
          status: CallHistoryStatus.ready,
          entries: state.entries,
          total: state.total,
        ),
      );
    }
  }
}
