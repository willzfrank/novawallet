import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/money/money.dart';
import '../../core/network/connectivity_provider.dart';
import '../../models/save_goal.dart';
import '../../queue/queue_processor.dart';
import 'save_provider.dart';

class SaveGoalsScreen extends ConsumerWidget {
  const SaveGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(saveGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('NovaSave')),
      floatingActionButton: Semantics(
        button: true,
        label: 'Create new save goal',
        hint: 'Double tap to create a NovaSave goal',
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CreateGoalScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('New goal'),
        ),
      ),
      body: goals.isEmpty
          ? const Center(child: Text('No goals yet — create one'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _GoalTile(goal: goal);
              },
            ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final SaveGoal goal;

  @override
  Widget build(BuildContext context) {
    final pct = goal.progressPercent;
    return Semantics(
      button: true,
      label:
          '${goal.name}, $pct percent funded, ${Money.formatKobo(goal.savedAmountKobo)} of ${Money.formatKobo(goal.targetAmountKobo)}',
      hint: 'Double tap to contribute to this goal',
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ContributeScreen(goalId: goal.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${Money.formatKobo(goal.savedAmountKobo)} / ${Money.formatKobo(goal.targetAmountKobo)} ($pct%)',
              ),
              const SizedBox(height: 8),
              Semantics(
                label: 'Progress $pct percent',
                child: LinearProgressIndicator(value: goal.progress),
              ),
              const Divider(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateGoalScreen extends HookConsumerWidget {
  const CreateGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final amountController = useTextEditingController();
    final targetDate = useState(DateTime.now().add(const Duration(days: 30)));
    final saving = useState(false);

    return Scaffold(
      appBar: AppBar(title: const Text('Create goal')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              textField: true,
              label: 'Goal name',
              hint: 'Enter goal name',
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              textField: true,
              label: 'Target amount in Naira',
              hint: 'Enter target amount',
              child: TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target amount (₦)',
                  border: OutlineInputBorder(),
                  prefixText: '₦ ',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Pick target date',
              hint: 'Double tap to choose target date',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target date'),
                subtitle: Text(
                  MaterialLocalizations.of(context)
                      .formatFullDate(targetDate.value),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate.value,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) targetDate.value = picked;
                },
              ),
            ),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Save new goal',
              hint: 'Double tap to create goal',
              child: FilledButton(
                onPressed: saving.value
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final kobo =
                            Money.nairaStringToKobo(amountController.text);
                        if (name.isEmpty || kobo == null || kobo <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter valid name and amount'),
                            ),
                          );
                          return;
                        }
                        saving.value = true;
                        await ref.read(saveGoalsProvider.notifier).createGoal(
                              name: name,
                              targetAmountKobo: kobo,
                              targetDate: targetDate.value,
                            );
                        saving.value = false;
                        if (context.mounted) Navigator.of(context).pop();
                      },
                child: const Text('Create goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContributeScreen extends HookConsumerWidget {
  const ContributeScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(saveGoalsProvider);
    final goal = goals.cast<SaveGoal?>().firstWhere(
          (g) => g?.id == goalId,
          orElse: () => null,
        );
    final amountController = useTextEditingController();
    final submitting = useState(false);

    if (goal == null) {
      return const Scaffold(
        body: Center(child: Text('Goal not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Contribute — ${goal.name}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Progress ${goal.progressPercent}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Goal progress ${goal.progressPercent} percent',
              child: LinearProgressIndicator(
                key: ValueKey('progress-${goal.id}-${goal.savedAmountKobo}'),
                value: goal.progress,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${Money.formatKobo(goal.savedAmountKobo)} / ${Money.formatKobo(goal.targetAmountKobo)}',
            ),
            const SizedBox(height: 24),
            Semantics(
              textField: true,
              label: 'Contribution amount in Naira',
              hint: 'Enter amount to contribute',
              child: TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  border: OutlineInputBorder(),
                  prefixText: '₦ ',
                ),
              ),
            ),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Contribute to ${goal.name}',
              hint: 'Double tap to contribute',
              child: FilledButton(
                onPressed: submitting.value
                    ? null
                    : () async {
                        final kobo =
                            Money.nairaStringToKobo(amountController.text);
                        if (kobo == null || kobo <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid amount'),
                            ),
                          );
                          return;
                        }
                        submitting.value = true;
                        final online = ref.read(isOnlineProvider);
                        final result = await ref
                            .read(queueProcessorProvider.notifier)
                            .submitOrQueue(
                              type: 'contribute',
                              payload: {
                                'goalId': goalId,
                                'amountKobo': kobo,
                              },
                              online: online,
                            );
                        submitting.value = false;
                        if (!context.mounted) return;
                        if (result.queuedOffline ||
                            ref
                                .read(appStorageProvider)
                                .queueBox
                                .containsKey(result.action.id)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pending — will send when back online',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Contributed ${Money.formatKobo(kobo)}',
                              ),
                            ),
                          );
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                child: submitting.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Contribute'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
