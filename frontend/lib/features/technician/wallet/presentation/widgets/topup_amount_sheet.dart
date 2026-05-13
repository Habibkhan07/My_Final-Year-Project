import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../notifiers/topup_notifier.dart';
import '../notifiers/topup_state.dart';

/// Modal bottom-sheet for entering the top-up amount.
///
/// Four quick-pick chips cover the common values; the text field
/// accepts any whole rupee between Rs.100 and Rs.25,000 (validated
/// server-side too — the FE check is UX, not security). On submit,
/// calls [TopupNotifier.start] and pops the sheet.
///
/// The wallet screen watches `topupProvider` and reacts to the
/// flow transitioning to `awaitingGateway` by pushing the webview —
/// this sheet is only responsible for collecting the amount.
class TopupAmountSheet extends ConsumerStatefulWidget {
  const TopupAmountSheet({super.key});

  @override
  ConsumerState<TopupAmountSheet> createState() => _TopupAmountSheetState();
}

class _TopupAmountSheetState extends ConsumerState<TopupAmountSheet> {
  static const _quickPicks = [200, 500, 1000, 2000];
  static const _minRupees = 100;
  static const _maxRupees = 25000;

  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parsedAmount() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  void _selectQuickPick(int amount) {
    _controller.text = amount.toString();
    setState(() => _errorText = null);
  }

  Future<void> _submit() async {
    final amount = _parsedAmount();
    if (amount == null) {
      setState(() => _errorText = 'Enter a whole-rupee amount.');
      return;
    }
    if (amount < _minRupees || amount > _maxRupees) {
      setState(
        () => _errorText = 'Enter between Rs.$_minRupees and Rs.$_maxRupees.',
      );
      return;
    }

    // Pop the sheet first so the wallet screen sees the state flip
    // through `starting → awaitingGateway` without the sheet still
    // sitting on top. The notifier survives the pop (it's scoped to
    // the wallet screen, not the sheet).
    Navigator.of(context).pop();
    await ref.read(topupProvider.notifier).start(amount);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(topupProvider).flow;
    final busy = flow == TopupFlow.starting;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Top up wallet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pay securely via JazzCash on the next screen.',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs. ',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.radiusLG),
                  ),
                ),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amount in _quickPicks)
                    ActionChip(
                      label: Text('Rs. $amount'),
                      onPressed: () => _selectQuickPick(amount),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppShapes.radiusXL),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
