import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/statistics_model.dart';
import '../../data/repositories/statistics_repository.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return StatisticsRepository(userId: userId);
});

final statisticsProvider = FutureProvider<StatisticsModel>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return await repository.getStatistics();
});

final refreshedStatisticsProvider =
    FutureProvider<StatisticsModel>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return await repository.getStatistics();
});

class StatisticsNotifier extends StateNotifier<AsyncValue<StatisticsModel>> {
  final StatisticsRepository _repository;

  StatisticsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getStatistics();
      if (mounted) {
        state = AsyncValue.data(stats);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refreshStatistics() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getStatistics();
      if (mounted) {
        state = AsyncValue.data(stats);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final statisticsNotifierProvider =
    StateNotifierProvider<StatisticsNotifier, AsyncValue<StatisticsModel>>(
        (ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return StatisticsNotifier(repository);
});
