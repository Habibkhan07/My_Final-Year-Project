import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../notifiers/topup_notifier.dart';
import '../notifiers/topup_state.dart';
import '../screens/jazzcash_webview_screen.dart';
import 'topup_amount_sheet.dart';
import 'topup_result_sheet.dart';

/// Wallet-screen CTA that opens the JazzCash Hosted Checkout flow.
///
/// Owns the cross-screen coordination — watches [TopupNotifier] state
/// and pushes either the webview screen (on ``awaitingGateway``) or
/// the result sheet (on a terminal state). The amount sheet, webview,
/// and result sheet are stateless surfaces that read the same notifier.
///
/// Why this widget watches: anything on the wallet screen could do it,
/// but [TopUpButton] is the only entry point and rebuilds cheaply, so
/// keeping the watcher local keeps the wallet screen widget tree free
/// of topup-specific listeners.
class TopUpButton extends ConsumerStatefulWidget {
  const TopUpButton({super.key});

  @override
  ConsumerState<TopUpButton> createState() => _TopUpButtonState();
}

class _TopUpButtonState extends ConsumerState<TopUpButton> {
  /// Tracks whether we've already pushed the webview / result sheet
  /// for the current state phase. Without this, every rebuild would
  /// try to push again.
  TopupFlow? _lastReactedFlow;

  /// Match prefix for the webview's NavigationDelegate. The bridge
  /// view's redirect URL points at our own backend, then JazzCash
  /// POSTs back to ``pp_ReturnURL``. The FE detects "the user is
  /// home" by URL prefix match — the path is stable across hosts so
  /// we anchor on that rather than the full URL.
  static const _returnUrlPath = '/api/wallet/gateway/jazzcash/return/';
  String get _returnUrlMatch {
    final base = AppConstants.baseUrl; // ends in /api
    // Strip trailing /api so we can append the canonical path verbatim.
    final origin = base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
    return '$origin$_returnUrlPath';
  }

  void _openAmountSheet() {
    ref.read(topupProvider.notifier).reset();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const TopupAmountSheet(),
    );
  }

  void _maybeReact(TopupState state) {
    if (_lastReactedFlow == state.flow) return;
    _lastReactedFlow = state.flow;

    if (state.flow == TopupFlow.awaitingGateway && state.session != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => JazzCashWebviewScreen(
            redirectUrl: state.session!.redirectUrl,
            returnUrlMatch: _returnUrlMatch,
          ),
        ),
      );
      return;
    }
    if (state.isTerminal) {
      // Don't trigger the result sheet for the implicit ``reset()``
      // path — only when we actually walked through the flow.
      if (state.flow == TopupFlow.idle) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const TopupResultSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen for one-shot reactions, not ref.watch — the button
    // itself doesn't need to rebuild when the flow phase changes.
    ref.listen<TopupState>(topupProvider, (previous, next) {
      _maybeReact(next);
    });

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openAmountSheet,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Top up'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusXL),
          ),
        ),
      ),
    );
  }
}
