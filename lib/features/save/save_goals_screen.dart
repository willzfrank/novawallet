import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/money/money.dart';
import '../../core/money/money_validator.dart';
import '../../core/money/naira_input_formatter.dart';
import '../../core/network/connectivity_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/save_goal.dart';
import '../../queue/queue_processor.dart';
import 'save_provider.dart';

class SaveGoalsScreen extends ConsumerWidget {
  const SaveGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goals = ref.watch(saveGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myGoals)),
      floatingActionButton: Semantics(
        button: true,
        label: l10n.createGoal,
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
          label: Text(l10n.createGoal),
        ),
      ),
      body: goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.noGoals),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: l10n.createGoal,
                    hint: 'Double tap to create a NovaSave goal',
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CreateGoalScreen(),
                          ),
                        );
                      },
                      child: Text(l10n.createGoal),
                    ),
                  ),
                ],
              ),
            )
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
    final l10n = AppLocalizations.of(context)!;
    final pct = goal.progressPercent;
    final saved = Money.formatKobo(goal.savedAmountKobo);
    final target = Money.formatKobo(goal.targetAmountKobo);
    return Semantics(
      button: true,
      label:
          '${goal.name}, $pct percent ${l10n.progress}, $saved ${l10n.ofLabel} $target',
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
                '${l10n.saved}: $saved ${l10n.ofLabel} $target ($pct%)',
              ),
              const SizedBox(height: 8),
              Semantics(
                label: '${l10n.progress} $pct percent',
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
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController();
    final amountController = useTextEditingController();
    final targetDate = useState(DateTime.now().add(const Duration(days: 30)));
    final saving = useState(false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGoal)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              textField: true,
              label: l10n.goalName,
              hint: 'Enter goal name',
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.goalName,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              textField: true,
              label: l10n.targetAmount,
              hint: 'Enter target amount',
              child: TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [NairaThousandsFormatter()],
                decoration: InputDecoration(
                  labelText: '${l10n.targetAmount} (₦)',
                  hintText: '40,000',
                  border: const OutlineInputBorder(),
                  prefixText: '₦ ',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: l10n.targetDate,
              hint: 'Double tap to choose target date',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.targetDate),
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
              label: l10n.createGoal,
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
                            SnackBar(content: Text(l10n.error)),
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
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.goalCreated)),
                        );
                        Navigator.of(context).pop();
                      },
                child: Text(l10n.createGoal),
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
    final l10n = AppLocalizations.of(context)!;
    final goals = ref.watch(saveGoalsProvider);
    final goal = goals.cast<SaveGoal?>().firstWhere(
          (g) => g?.id == goalId,
          orElse: () => null,
        );
    final amountController = useTextEditingController();
    final submitting = useState(false);

    if (goal == null) {
      return Scaffold(
        body: Center(child: Text(l10n.error)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.contribute} — ${goal.name}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.progress} ${goal.progressPercent}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Semantics(
              label: '${l10n.progress} ${goal.progressPercent} percent',
              child: LinearProgressIndicator(
                key: ValueKey('progress-${goal.id}-${goal.savedAmountKobo}'),
                value: goal.progress,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.saved}: ${Money.formatKobo(goal.savedAmountKobo)} ${l10n.ofLabel} ${Money.formatKobo(goal.targetAmountKobo)}',
            ),
            const SizedBox(height: 24),
            Semantics(
              textField: true,
              label: l10n.amount,
              hint: 'Enter amount to contribute',
              child: TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [NairaThousandsFormatter()],
                decoration: InputDecoration(
                  labelText: '${l10n.amount} (₦)',
                  hintText: '1,500.75',
                  border: const OutlineInputBorder(),
                  prefixText: '₦ ',
                ),
              ),
            ),
            const Spacer(),
            Semantics(
              button: true,
              label: '${l10n.contribute} ${goal.name}',
              hint: 'Double tap to contribute',
              child: FilledButton(
                onPressed: submitting.value
                    ? null
                    : () async {
                        final kobo =
                            Money.nairaStringToKobo(amountController.text);
                        if (kobo == null || kobo <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.error)),
                          );
                          return;
                        }
                        final err = await MoneyValidator.validate(
                          kobo,
                          ref.read(appStorageProvider),
                        );
                        if (!context.mounted) return;
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                err == 'Insufficient balance'
                                    ? l10n.insufficientBalance
                                    : err,
                              ),
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
                        final stillQueued = ref
                            .read(appStorageProvider)
                            .queueBox
                            .containsKey(result.action.id);
                        if (!online || stillQueued) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.contributed)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.success)),
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
                    : Text(l10n.contribute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
