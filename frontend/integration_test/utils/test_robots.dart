import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

abstract class BaseRobot {
  final WidgetTester tester;
  BaseRobot(this.tester);

  Future<void> enterText(Finder finder, String text) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  void expectText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  Future<void> waitFor(Finder finder, {Duration timeout = const Duration(seconds: 10)}) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    throw Exception('Timed out waiting for finder: $finder');
  }

  Future<void> waitForText(String text, {Duration timeout = const Duration(seconds: 10)}) async {
    await waitFor(find.text(text), timeout: timeout);
  }
}

class AuthRobot extends BaseRobot {
  AuthRobot(super.tester);

  // --- Login Screen Actions ---
  Future<void> enterPhoneNumber(String phone) async {
    final field = find.byType(IntlPhoneField);
    await tester.enterText(field, phone);
    await tester.pumpAndSettle();
  }

  Future<void> tapSendCode() async {
    await tap(find.text('Send Verification Code'));
  }

  // --- OTP Screen Actions ---
  Future<void> enterOtp(String code) async {
    // OTP field has hint "000000"
    final field = find.widgetWithText(TextField, "000000");
    await enterText(field, code);
  }

  Future<void> tapVerify() async {
    await tap(find.text('Verify & Continue'));
  }

  // --- Profile Setup Actions ---
  Future<void> enterProfileDetails(String firstName, String lastName) async {
    await enterText(find.widgetWithText(TextField, 'First Name'), firstName);
    await enterText(find.widgetWithText(TextField, 'Last Name'), lastName);
  }

  Future<void> tapFinishSetup() async {
    await tap(find.text('Finish Setup'));
  }
}

class CommonRobot extends BaseRobot {
  CommonRobot(super.tester);

  void expectSnackbar(String message) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(message), findsOneWidget);
  }

  Future<void> dismissSnackbar() async {
    ScaffoldMessenger.of(tester.element(find.byType(SnackBar).first)).clearSnackBars();
    await tester.pumpAndSettle();
  }

  Future<void> goBack() async {
    final backButton = find.byIcon(Icons.arrow_back).evaluate().isNotEmpty 
        ? find.byIcon(Icons.arrow_back)
        : find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tap(backButton);
  }
}

class HomeRobot extends BaseRobot {
  HomeRobot(super.tester);

  void expectLocationHeader(String location) {
    expect(find.text('Current Location'), findsOneWidget);
    expect(find.text(location), findsOneWidget);
  }

  Future<void> tapSearchField() async {
    await tap(find.text('Try "AC not cooling" or "Leaky pipe"...'));
  }

  Future<void> tapCategory(String categoryName) async {
    // Categories are in a Row, use descendant if needed
    await tap(find.text(categoryName));
  }

  Future<void> tapFixedGig(String gigName) async {
    await tap(find.text(gigName));
  }

  Future<void> pullToRefresh() async {
    // SingleChildScrollView is used for the scrollable body
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, 300.0));
    await tester.pumpAndSettle();
  }

  void expectSectionTitle(String title) {
    expect(find.text(title), findsOneWidget);
  }
}

class SearchRobot extends BaseRobot {
  SearchRobot(super.tester);

  Future<void> enterSearchQuery(String query) async {
    final field = find.widgetWithText(TextField, 'Search for services...');
    await enterText(field, query);
  }

  void expectSuggestion(String suggestion) {
    expect(find.text(suggestion), findsOneWidget);
  }

  Future<void> tapSuggestion(String suggestion) async {
    await tap(find.text(suggestion));
  }
}

class DiscoveryRobot extends BaseRobot {
  DiscoveryRobot(super.tester);

  void expectTitle(String title) {
    expect(find.descendant(of: find.byType(AppBar), matching: find.text(title)), findsOneWidget);
  }

  void expectTechnician(String name) {
    expect(find.text(name), findsOneWidget);
  }
}
