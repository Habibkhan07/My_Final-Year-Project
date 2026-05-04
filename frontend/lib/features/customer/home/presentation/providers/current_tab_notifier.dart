import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_tab_notifier.g.dart';

/// Active bottom-nav index for the customer's home shell.
///
/// Scoped to the home-screen mount (NOT `keepAlive`): a logout +
/// re-entry resets to Home (index 0), which matches what users expect
/// when re-launching the app or switching accounts.
///
/// Indices: 0 = Home, 1 = Bookings, 2 = Messages, 3 = Profile.
@riverpod
class CurrentCustomerTab extends _$CurrentCustomerTab {
  @override
  int build() => 0;

  /// Switch to [index]. Same-value sets are dropped so dependent widgets
  /// don't rebuild when the user re-taps the active tab.
  void set(int index) {
    if (state == index) return;
    state = index;
  }
}
