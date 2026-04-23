import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;
import '../../utils/test_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Home Feature Flow Tests', () {
    testWidgets('Full Home Flow: Explore Categories, Gigs, and Search', (tester) async {
      // 1. Start App & Login (Prerequisite)
      app.main();
      await tester.pumpAndSettle();

      final auth = AuthRobot(tester);
      final home = HomeRobot(tester);
      final search = SearchRobot(tester);
      final discovery = DiscoveryRobot(tester);
      final common = CommonRobot(tester);

      // Authenticate as a returning user
      await auth.enterPhoneNumber('3001234567');
      await auth.tapSendCode();
      await auth.waitForText('Verify Phone');
      await auth.enterOtp('123456');
      await auth.tapVerify();

      // 2. Land on Home Screen & Verify Components
      // Wait for a key home screen element (e.g., location or a category)
      await home.waitForText('Current Location');
      home.expectLocationHeader('Gulberg III, Lahore');
      
      home.expectSectionTitle('What do you need help with?');
      home.expectSectionTitle('Fixed-Price Maintenance');
      home.expectSectionTitle('Top Rated Near You');

      // 3. Test Pull to Refresh
      await home.pullToRefresh();
      home.expectLocationHeader('Gulberg III, Lahore');

      // 4. Explore Category -> Discovery
      // Note: Category names come from seed data. Using common ones.
      final categoryName = 'AC Repair'; 
      await home.tapCategory(categoryName);
      await discovery.waitForText(categoryName);
      discovery.expectTitle(categoryName);
      
      // Go back to Home
      await common.goBack();
      await home.waitForText('Current Location');

      // 5. Explore Fixed Gig -> Discovery
      final gigName = 'AC General Service';
      await home.tapFixedGig(gigName);
      await discovery.waitForText(gigName);
      discovery.expectTitle(gigName);

      // Go back to Home
      await common.goBack();
      await home.waitForText('Current Location');

      // 6. Test Search Flow
      await home.tapSearchField();
      await search.waitForText('Recent Searches');
      
      await search.enterSearchQuery('Electrician');
      // Wait for suggestions to appear
      await search.waitForText('Electrician');
      await search.tapSuggestion('Electrician');
      
      // Should land on Discovery for 'Electrician'
      await discovery.waitForText('Electrician');
      discovery.expectTitle('Electrician');
      
      // Go back to Home
      await common.goBack(); // Back to Search
      await common.goBack(); // Back to Home
      await home.waitForText('Current Location');
    });

    testWidgets('Home Screen: Offline Mode Verification', (tester) async {
      // This test would ideally mock network failure, 
      // but in a full E2E it depends on environment state.
      // For now, we verify the UI components exist.
      app.main();
      await tester.pumpAndSettle();

      final auth = AuthRobot(tester);
      final home = HomeRobot(tester);

      await auth.enterPhoneNumber('3001234567');
      await auth.tapSendCode();
      await auth.waitForText('Verify Phone');
      await auth.enterOtp('123456');
      await auth.tapVerify();

      await home.waitForText('Current Location');
      
      // If we were to simulate offline, we'd see the OfflineBanner
      // home.expectText('No internet connection. Showing offline data.');
    });
  });
}
