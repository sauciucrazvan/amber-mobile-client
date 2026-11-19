import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/core/network/server_time.dart';
import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:dio/dio.dart';

/// One call in the history, as the backend's call summary gives it.
class CallHistoryEntry {
  const CallHistoryEntry({
    required this.callId,
    required this.status,
    required this.mode,
    required this.peer,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.endReason,
  });

  factory CallHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CallHistoryEntry(
      callId: json['call_id'] as String,
      status: json['status'] as String,
      mode: CallMode.parse(json['call_mode']),
      peer: CallPeer.fromJson(json['peer'] as Map<String, dynamic>),
      startedAt: parseServerTime(json['started_at']),
      endedAt: parseServerTime(json['ended_at']),
      durationSeconds: (json['duration_seconds'] as int?) ?? 0,
      endReason: json['end_reason'] as String?,
    );
  }

  final String callId;
  final String status;
  final CallMode mode;
  final CallPeer peer;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? endReason;

  /// The reason the call ended, or its status when there is none.
  String get reason => endReason ?? status;

  /// When the call started, or ended if it never connected.
  DateTime? get when => startedAt ?? endedAt;

  /// Missed, failed or refused calls, which the desktop shows in red. The
  /// rule matches the desktop's `CallHistoryTab`.
  bool get isMissed =>
      status == 'missed' ||
      status == 'failed' ||
      const {'missed', 'timeout', 'failed', 'rejected'}.contains(endReason);
}

class CallHistoryPage {
  const CallHistoryPage({required this.total, required this.entries});

  final int total;
  final List<CallHistoryEntry> entries;
}

/// Calls `GET /calls/v1/history`, one page at a time.
class CallHistoryApi {
  CallHistoryApi(this._client);

  final ApiClient _client;

  Future<CallHistoryPage> page({required int offset, int limit = 50}) async {
    try {
      final response = await _client.request<Map<String, dynamic>>(
        '/calls/v1/history?limit=$limit&offset=$offset',
      );
      final data = response.data!;
      return CallHistoryPage(
        total: data['total'] as int,
        entries: [
          for (final call in data['calls'] as List<dynamic>)
            CallHistoryEntry.fromJson(call as Map<String, dynamic>),
        ],
      );
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
