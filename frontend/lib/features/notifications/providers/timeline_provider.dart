import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/data/datasources/timeline_remote_data_source.dart';

class TimelineState {
  final bool isLoading;
  final Map<String, dynamic>? reviewData;
  final List<Map<String, dynamic>> reflections;
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final String? errorMessage;

  const TimelineState({
    this.isLoading = false,
    this.reviewData,
    this.reflections = const [],
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  TimelineState copyWith({
    bool? isLoading,
    Map<String, dynamic>? reviewData,
    List<Map<String, dynamic>>? reflections,
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return TimelineState(
      isLoading: isLoading ?? this.isLoading,
      reviewData: reviewData ?? this.reviewData,
      reflections: reflections ?? this.reflections,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }
}

class TimelineNotifier extends Notifier<TimelineState> {
  @override
  TimelineState build() {
    Future.microtask(() => loadAll());
    return const TimelineState(isLoading: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      final results = await Future.wait([
        ds.getReviewScreen(),
        ds.getReflections(limit: 20),
        ds.getNotifications(),
      ]);

      final notifications =
          (results[2] as List).cast<Map<String, dynamic>>();
      final unread = notifications
          .where((n) => n['read'] == false || n['readAt'] == null)
          .length;

      state = state.copyWith(
        isLoading: false,
        reviewData: results[0] as Map<String, dynamic>,
        reflections: (results[1] as List).cast<Map<String, dynamic>>(),
        notifications: notifications,
        unreadCount: unread,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> markRead(String id) async {
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      await ds.markNotificationRead(id);
      final updated = state.notifications.map((n) {
        if (n['_id'] == id) return {...n, 'readAt': DateTime.now().toIso8601String()};
        return n;
      }).toList();
      final unread = updated
          .where((n) => n['read'] == false || n['readAt'] == null)
          .length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (_) {}
  }

  Future<bool> createReflection({
    required DateTime periodStart,
    required DateTime periodEnd,
    String? text,
    int? moodScore,
  }) async {
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      await ds.createReflection(
        periodStart: periodStart.toIso8601String(),
        periodEnd: periodEnd.toIso8601String(),
        text: text,
        moodScore: moodScore,
      );
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final timelineProvider =
    NotifierProvider<TimelineNotifier, TimelineState>(TimelineNotifier.new);
