import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/money/money.dart';
import '../../core/network/connectivity_provider.dart';
import '../../queue/queue_processor.dart';

const List<String> kMockContacts = [
  'Ada Okafor',
  'Kunle Adebayo',
  'Chioma Eze',
  'Tunde Bakare',
  'Fatima Bello',
];

class SendMoneyFlow extends HookConsumerWidget {
  const SendMoneyFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(0);
    final recipientController = useTextEditingController();
    final amountController = useTextEditingController();
    final selectedContact = useState<String?>(null);
    final amountKobo = useState<int?>(null);
    final idempotencyPreview = useState<String?>(null);
    final submitting = useState(false);

    String recipient() {
      final typed = recipientController.text.trim();
      if (typed.isNotEmpty) return typed;
      return selectedContact.value ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Send Money — Step ${step.value + 1}/3'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: step.value == 0
              ? _StepRecipient(
                  controller: recipientController,
                  selectedContact: selectedContact.value,
                  onContactSelected: (c) {
                    selectedContact.value = c;
                    recipientController.text = c;
                  },
                  onNext: () {
                    if (recipient().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter or pick a recipient')),
                      );
                      return;
                    }
                    step.value = 1;
                  },
                )
              : step.value == 1
                  ? _StepAmount(
                      controller: amountController,
                      onBack: () => step.value = 0,
                      onNext: () {
                        final kobo =
                            Money.nairaStringToKobo(amountController.text);
                        if (kobo == null || kobo <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid amount in Naira'),
                            ),
                          );
                          return;
                        }
                        amountKobo.value = kobo;
                        idempotencyPreview.value = const Uuid().v4();
                        step.value = 2;
                      },
                    )
                  : _StepConfirm(
                      recipient: recipient(),
                      amountKobo: amountKobo.value ?? 0,
                      idempotencyKey: idempotencyPreview.value,
                      submitting: submitting.value,
                      onBack: () => step.value = 1,
                      onConfirm: () async {
                        if (amountKobo.value == null ||
                            idempotencyPreview.value == null) {
                          return;
                        }
                        submitting.value = true;
                        try {
                          final online = ref.read(isOnlineProvider);
                          final result = await ref
                              .read(queueProcessorProvider.notifier)
                              .submitOrQueue(
                                type: 'send',
                                payload: {
                                  'recipient': recipient(),
                                  'amountKobo': amountKobo.value,
                                },
                                online: online,
                                idempotencyKey: idempotencyPreview.value,
                              );
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
                                  'Sent ${Money.formatKobo(amountKobo.value!)} to ${recipient()}',
                                ),
                              ),
                            );
                          }
                          if (context.mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        } finally {
                          if (context.mounted) submitting.value = false;
                        }
                      },
                    ),
        ),
      ),
    );
  }
}

class _StepRecipient extends StatelessWidget {
  const _StepRecipient({
    required this.controller,
    required this.selectedContact,
    required this.onContactSelected,
    required this.onNext,
  });

  final TextEditingController controller;
  final String? selectedContact;
  final ValueChanged<String> onContactSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          textField: true,
          label: 'Recipient name or account',
          hint: 'Enter recipient',
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Recipient',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        Text('Or pick a contact', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: kMockContacts.length,
            itemBuilder: (context, index) {
              final contact = kMockContacts[index];
              final selected = selectedContact == contact;
              return Semantics(
                button: true,
                label: 'Contact $contact',
                hint: 'Double tap to select $contact',
                selected: selected,
                child: ListTile(
                  selected: selected,
                  title: Text(contact),
                  trailing: selected
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.person_outline),
                  onTap: () => onContactSelected(contact),
                ),
              );
            },
          ),
        ),
        Semantics(
          button: true,
          label: 'Continue to amount',
          hint: 'Double tap to go to amount step',
          child: FilledButton(
            key: const Key('send_next_recipient'),
            onPressed: onNext,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }
}

class _StepAmount extends StatelessWidget {
  const _StepAmount({
    required this.controller,
    required this.onBack,
    required this.onNext,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          textField: true,
          label: 'Amount in Naira',
          hint: 'Enter amount to send',
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (₦)',
              hintText: '1500.75',
              border: OutlineInputBorder(),
              prefixText: '₦ ',
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Back to recipient',
                hint: 'Double tap to go back',
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Continue to confirm',
                hint: 'Double tap to review transfer',
                child: FilledButton(
                  key: const Key('send_next_amount'),
                  onPressed: onNext,
                  child: const Text('Next'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    required this.recipient,
    required this.amountKobo,
    required this.idempotencyKey,
    required this.submitting,
    required this.onBack,
    required this.onConfirm,
  });

  final String recipient;
  final int amountKobo;
  final String? idempotencyKey;
  final bool submitting;
  final VoidCallback onBack;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final formatted = Money.formatKobo(amountKobo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm transfer', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        ListTile(
          title: const Text('Recipient'),
          subtitle: Text(recipient),
        ),
        ListTile(
          title: const Text('Amount'),
          subtitle: Text(formatted),
        ),
        ListTile(
          title: const Text('Idempotency key (debug)'),
          subtitle: Text(
            idempotencyKey ?? '—',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Back to amount',
                hint: 'Double tap to go back',
                child: OutlinedButton(
                  onPressed: submitting ? null : onBack,
                  child: const Text('Back'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Confirm send $formatted to $recipient',
                hint: 'Double tap to confirm transfer',
                child: FilledButton(
                  key: const Key('send_confirm'),
                  onPressed: submitting
                      ? null
                      : () {
                          onConfirm();
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
