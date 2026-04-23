import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;
import '../../utils/test_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Routing Matrix & Journey Tests', () {
    testWidgets('New User: Full Signup Journey (Login -> OTP -> Profile -> Home)', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final auth = AuthRobot(tester);
      final common = CommonRobot(tester);

      // 1. Login Screen
      auth.expectText('Start with your phone no');
      await auth.enterPhoneNumber('3000000001'); // Using a new number
      await auth.tapSendCode();
      
      // 2. Wait for OTP Screen & Verify
      await auth.waitForText('Verify Phone');
      auth.expectText('3000000001');
      await auth.enterOtp('123456'); // [DEV OTP] from CLAUDE.md
      await auth.tapVerify();

      // 3. Wait for Profile Setup (Since new_user/name_required = true)
      await auth.waitForText('Create Your Profile');
      await auth.enterProfileDetails('Integration', 'Tester');
      await auth.tapFinishSetup();

      // 4. Land on Home Screen
      await auth.waitForText('Home'); // Assuming 'Home' text exists on HomeScreen
      auth.expectText('Welcome, Integration'); // "Dumb UI" validation
    });

    testWidgets('Returning User: Skip Profile Setup (Login -> OTP -> Home)', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final auth = AuthRobot(tester);

      // 1. Login Screen
      await auth.enterPhoneNumber('3001234567'); // Assume this exists in seed data
      await auth.tapSendCode();
      
      // 2. OTP Screen
      await auth.waitForText('Verify Phone');
      await auth.enterOtp('123456');
      await auth.tapVerify();

      // 3. Skip Profile & Land on Home (Since name_required = false)
      await auth.waitForText('Home');
    });

    testWidgets('Error Pipeline: Wrong OTP displays Backend Message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final auth = AuthRobot(tester);
      final common = CommonRobot(tester);

      // 1. Login -> OTP
      await auth.enterPhoneNumber('3001234567');
      await auth.tapSendCode();
      await auth.waitForText('Verify Phone');

      // 2. Enter Invalid OTP
      await auth.enterOtp('000000');
      await auth.tapVerify();

      // 3. Assert Backend Error Envelope logic
      // Assuming backend returns: {"code": "validation_error", "message": "Invalid OTP code", "errors": {"otp": ["Invalid OTP."]}}
      // Our OtpScreen logic priority: errors['otp'] first.
      await common.waitForText('Invalid OTP.'); 
      common.expectSnackbar('Invalid OTP.');
    });
  });
}
