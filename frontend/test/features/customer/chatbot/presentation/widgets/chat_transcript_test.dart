// Widget tests for ChatTranscript.
//
// Verifies the scroll-behaviour contract:
//   * Empty / initial render shows every bubble.
//   * Appending a message auto-scrolls toward the bottom.
//   * Appending while the user is scrolled up >100px suppresses the
//     auto-scroll (don't yank the reader back).
//
// The transcript uses a postFrame callback + animateTo(); after each
// state update we `pumpAndSettle()` so the 300 ms animation finishes
// before reading `controller.position`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_message.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_phase.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/chat_transcript.dart';

ChatMessage _msg(int id) => ChatMessage(
      id: id,
      role: id.isEven ? ChatRole.bot : ChatRole.user,
      // Short one-line text. Each bubble adds <100 px of vertical
      // extent so the auto-scroll suppression (which fires when the
      // post-update distance-from-bottom exceeds 100 px) does NOT
      // trigger for a single-append.
      text: 'msg $id',
      createdAt: DateTime.utc(2026, 5, 14, 3, 21, 55),
      phase: ChatPhase.understand,
    );

/// Test harness: lets us swap the message list mid-test so the
/// transcript receives a `didUpdateWidget` with a longer list.
class _Harness extends StatefulWidget {
  final List<ChatMessage> initial;
  const _Harness({super.key, required this.initial});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<ChatMessage> _messages = widget.initial;

  void update(List<ChatMessage> next) => setState(() => _messages = next);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: ChatTranscript(messages: _messages),
        ),
      ),
    );
  }
}

ScrollController _findController(WidgetTester tester) {
  final scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
  return scrollable.controller!;
}

void main() {
  testWidgets('initial render shows every message in the list', (
    tester,
  ) async {
    final messages = List.generate(3, _msg);
    await tester.pumpWidget(_Harness(initial: messages));
    await tester.pump();

    expect(find.text('msg 0'), findsOneWidget);
    expect(find.text('msg 1'), findsOneWidget);
    expect(find.text('msg 2'), findsOneWidget);
  });

  testWidgets(
    'appending while near the bottom auto-scrolls to follow the new bubble',
    (tester) async {
      final key = GlobalKey<_HarnessState>();
      final initial = List.generate(8, _msg);
      await tester.pumpWidget(_Harness(key: key, initial: initial));
      await tester.pumpAndSettle();

      final controller = _findController(tester);
      // Park the user near the bottom (the auto-scroll's
      // distance-from-bottom suppression treats us as "actively
      // reading the latest" only when within 100 px of the floor).
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      final pixelsBefore = controller.position.pixels;
      final maxBefore = controller.position.maxScrollExtent;

      // Append a new bubble.
      key.currentState!.update([...initial, _msg(8)]);
      await tester.pump(); // build new list
      await tester.pumpAndSettle(const Duration(seconds: 1)); // animate

      // maxScrollExtent grew (new bubble added vertical extent), AND
      // we followed it down — pixels advanced past where we were.
      expect(
        controller.position.maxScrollExtent,
        greaterThan(maxBefore),
        reason: 'extent should grow when a new bubble is added',
      );
      expect(
        controller.position.pixels,
        greaterThan(pixelsBefore),
        reason: 'expected scroll position to advance after append',
      );
    },
  );

  testWidgets(
    'self-send: appending a tall bubble while at-bottom still auto-scrolls (P0-2 regression)',
    (tester) async {
      // Regression for the audit's P0-2: the OLD code measured
      // `distanceFromBottom` *after* the new bubble laid out — so a
      // user who just typed a tall message and tapped Send would
      // self-suppress their own scroll because the new bubble alone
      // exceeded the 100 px threshold. The FIX samples the user's
      // proximity to the bottom *before* the update.
      final key = GlobalKey<_HarnessState>();
      final initial = List.generate(8, _msg);
      await tester.pumpWidget(_Harness(key: key, initial: initial));
      await tester.pumpAndSettle();

      final controller = _findController(tester);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      final pixelsBefore = controller.position.pixels;

      // Append a single bubble whose rendered height alone exceeds the
      // suppression threshold (long wrapped text).
      final tall = ChatMessage(
        id: 999,
        role: ChatRole.user,
        text: 'a very long self-sent message ' * 30,
        createdAt: DateTime.utc(2026, 5, 14, 3, 21, 55),
        phase: ChatPhase.understand,
      );
      key.currentState!.update([...initial, tall]);
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // With the fix, the scroll position advances down toward the new
      // bottom even though the bubble itself is tall.
      expect(
        controller.position.pixels,
        greaterThan(pixelsBefore),
        reason: 'tall self-send while at-bottom should still scroll down',
      );
    },
  );

  testWidgets(
    'appending while scrolled up >100px does NOT auto-scroll',
    (tester) async {
      final key = GlobalKey<_HarnessState>();
      // Enough bubbles that the list has substantial extent — we need
      // room to scroll up >100 px and still be a long way from 0.
      final initial = List.generate(30, _msg);
      await tester.pumpWidget(_Harness(key: key, initial: initial));
      await tester.pumpAndSettle();

      final controller = _findController(tester);
      expect(
        controller.position.maxScrollExtent,
        greaterThan(200),
        reason: 'precondition: list must be tall enough to scroll meaningfully',
      );

      // Simulate user scrolling up to read history (well past 100 px
      // suppression threshold).
      final scrolledUpTo = controller.position.maxScrollExtent - 300;
      controller.jumpTo(scrolledUpTo);
      await tester.pump();

      key.currentState!.update([...initial, _msg(99)]);
      await tester.pump();
      await tester.pumpAndSettle();

      // Scroll position preserved (no animateTo fired).
      expect(
        (controller.position.pixels - scrolledUpTo).abs(),
        lessThan(5.0),
        reason: 'expected scroll position to be preserved',
      );
    },
  );
}
