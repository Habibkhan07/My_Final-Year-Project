import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../notifiers/topup_notifier.dart';

/// In-app webview that hosts the JazzCash Hosted Checkout flow.
///
/// Lifecycle:
///   1. ``initState`` — load the bridge URL the [TopupNotifier]
///      received from ``start_topup``.
///   2. The bridge auto-submits the JazzCash form (real gateway) or
///      shows Pay/Decline buttons (mock gateway demo fallback).
///   3. After the JazzCash hosted flow completes, JazzCash POSTs the
///      browser back to our ``pp_ReturnURL``
///      (``/api/wallet/gateway/jazzcash/return/``). The webview's
///      [NavigationDelegate] intercepts that URL match and calls
///      [TopupNotifier.onGatewayReturned], which kicks off the poll.
///   4. The notifier transitions to a terminal state via polling;
///      this screen pops itself either way (the wallet screen reacts
///      to the terminal state by showing the result sheet).
///
/// If the tech taps the Close action or system back gesture, we call
/// [TopupNotifier.onGatewayAborted] before popping so the result sheet
/// reflects the user-cancel.
class JazzCashWebviewScreen extends ConsumerStatefulWidget {
  final String redirectUrl;

  /// URL prefix the [NavigationDelegate] should treat as "the flow has
  /// finished" — anything starting with this string fires
  /// [TopupNotifier.onGatewayReturned] and pops the screen.
  ///
  /// Pass the full return URL the backend issued via
  /// ``JAZZCASH_RETURN_URL`` so the FE and BE agree on the boundary.
  /// In production this is wired through the app's bootstrap layer.
  final String returnUrlMatch;

  const JazzCashWebviewScreen({
    super.key,
    required this.redirectUrl,
    required this.returnUrlMatch,
  });

  @override
  ConsumerState<JazzCashWebviewScreen> createState() =>
      _JazzCashWebviewScreenState();
}

class _JazzCashWebviewScreenState extends ConsumerState<JazzCashWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _didNotifyReturn = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            // The return URL match closes the loop. Fire onGatewayReturned
            // (idempotent — the notifier guards against re-entry) and
            // pop. We DO NOT actually let the webview load the return
            // URL — the page is rendered server-side; we don't need it.
            if (request.url.startsWith(widget.returnUrlMatch) &&
                !_didNotifyReturn) {
              _didNotifyReturn = true;
              ref.read(topupProvider.notifier).onGatewayReturned();
              // Pop on the next frame so the navigation delegate can
              // safely return PREVENT first.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop();
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  /// Synchronous — calls into the notifier and returns whether the
  /// route may pop. Kept sync so the close-button onPressed doesn't
  /// have to await anything (avoids the use_build_context_synchronously
  /// false positive while keeping the abort call site obvious).
  bool _onWillPop() {
    if (_didNotifyReturn) return true;
    ref.read(topupProvider.notifier).onGatewayAborted();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        if (!_didNotifyReturn) {
          ref.read(topupProvider.notifier).onGatewayAborted();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('JazzCash'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel top-up',
            onPressed: () {
              if (_onWillPop()) Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
