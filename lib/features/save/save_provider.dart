import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../models/save_goal.dart';
import '../../queue/queue_processor.dart';

part 'save_provider.g.dart';

@riverpod
class SaveGoals extends _$SaveGoals {
  static const _uuid = Uuid();

  @override
  List<SaveGoal> build() {
    final storage = ref.watch(appStorageProvider);
    return storage.goalsBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<SaveGoal> createGoal({
    required String name,
    required int targetAmountKobo,
    required DateTime targetDate,
  }) async {
    final storage = ref.read(appStorageProvider);
    final goal = SaveGoal(
      id: _uuid.v4(),
      name: name,
      targetAmountKobo: targetAmountKobo,
      savedAmountKobo: 0,
      targetDate: targetDate,
    );
    await storage.goalsBox.put(goal.id, goal);
    state = storage.goalsBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return goal;
  }

  void reload() {
    final storage = ref.read(appStorageProvider);
    state = storage.goalsBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
