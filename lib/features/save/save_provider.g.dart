part of 'save_provider.dart';

@ProviderFor(SaveGoals)
final saveGoalsProvider =
    NotifierProvider<SaveGoals, List<SaveGoal>>(SaveGoals.new);

abstract class _$SaveGoals extends Notifier<List<SaveGoal>> {}
