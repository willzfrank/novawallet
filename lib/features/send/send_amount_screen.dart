import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/money/money.dart';
import '../../l10n/app_localizations.dart';

/// Amount step with live ₦ preview (validate only on Next).
class SendAmountScreen extends StatefulHookConsumerWidget {
  const SendAmountScreen({
    super.key,
    required this.amountLabel,
    required this.onBack,
    required this.onNext,
    this.initialText = '',
  });

  final String amountLabel;
  final VoidCallback onBack;
  final ValueChanged<String> onNext;
  final String initialText;

  @override
  ConsumerState<SendAmountScreen> createState() => _SendAmountScreenState();
}

class _SendAmountScreenState extends ConsumerState<SendAmountScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = useTextEditingController(text: widget.initialText);
    useListenable(controller);

    final kobo = Money.nairaStringToKobo(controller.text);
    final preview = kobo == null ? null : Money.formatKobo(kobo);

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
            decoration: InputDecoration(
              labelText: '${widget.amountLabel} (₦)',
              hintText: '1500.75',
              border: const OutlineInputBorder(),
              prefixText: '₦ ',
            ),
          ),
        ),
        if (preview != null) ...[
          const SizedBox(height: 12),
          Semantics(
            label: 'Amount preview: $preview',
            child: Text(
              preview,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Back to recipient',
                hint: 'Double tap to go back',
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: Text(l10n.back),
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
                  onPressed: () => widget.onNext(controller.text),
                  child: Text(l10n.next),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
