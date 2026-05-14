// Widget tests for ChatBubble.
//
// Pattern (per CLAUDE.md): inject hardcoded ChatMessage instances and
// assert that the visual contract holds. No network mocks — the widget
// is a `StatelessWidget` with no provider dependencies.
//
// Coverage:
//   * USER: bubble background == brand primary, ink == white,
//     alignment right.
//   * BOT: bubble background == bot cool-grey, alignment left.
//   * SYSTEM: no bubble (no Container with brand-blue background),
//     italic centered text.
//   * UNKNOWN role: renders as a SYSTEM line (defensive default).
//   * Long text: doesn't overflow — wrapping respects the 75% width
//     constraint without throwing a RenderFlex error.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_message.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_phase.dart';
import 'package:frontend/features/customer/chatbot/presentation/utils/chatbot_palette.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/chat_bubble.dart';

ChatMessage _msg({
  int id = 1,
  required ChatRole role,
  String text = 'hello',
}) {
  return ChatMessage(
    id: id,
    role: role,
    text: text,
    createdAt: DateTime.utc(2026, 5, 14, 3, 21, 55),
    phase: ChatPhase.understand,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

/// Find a Container whose decoration is a BoxDecoration with the given
/// solid color. Helps assert the bubble's background without depending
/// on layout details.
Iterable<Container> _containersWithColor(WidgetTester t, Color color) {
  return t
      .widgetList<Container>(find.byType(Container))
      .where((c) => c.decoration is BoxDecoration)
      .where(
        (c) => (c.decoration! as BoxDecoration).color == color,
      );
}

void main() {
  testWidgets('USER bubble: brand-blue background, white text', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(ChatBubble(message: _msg(role: ChatRole.user, text: 'hi'))));

    expect(find.text('hi'), findsOneWidget);
    // Brand-blue background container is present.
    expect(
      _containersWithColor(tester, ChatbotPalette.userBubble).isNotEmpty,
      isTrue,
    );
    // Text ink is white.
    final textWidget = tester.widget<Text>(find.text('hi'));
    expect(textWidget.style?.color, ChatbotPalette.userBubbleInk);
  });

  testWidgets('USER bubble: right-aligned via Align', (tester) async {
    await tester.pumpWidget(_wrap(ChatBubble(message: _msg(role: ChatRole.user, text: 'hi'))));
    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, Alignment.centerRight);
  });

  testWidgets('BOT bubble: cool-grey background, left-aligned', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(ChatBubble(message: _msg(role: ChatRole.bot, text: 'ok'))));

    expect(find.text('ok'), findsOneWidget);
    expect(
      _containersWithColor(tester, ChatbotPalette.botBubble).isNotEmpty,
      isTrue,
    );
    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, Alignment.centerLeft);
  });

  testWidgets(
    'SYSTEM message: italic centered text, NO bubble container',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ChatBubble(
            message: _msg(role: ChatRole.system, text: 'closed.'),
          ),
        ),
      );

      expect(find.text('closed.'), findsOneWidget);
      final txt = tester.widget<Text>(find.text('closed.'));
      expect(txt.style?.fontStyle, FontStyle.italic);
      expect(txt.textAlign, TextAlign.center);

      // No USER nor BOT colored container.
      expect(
        _containersWithColor(tester, ChatbotPalette.userBubble),
        isEmpty,
      );
      expect(
        _containersWithColor(tester, ChatbotPalette.botBubble),
        isEmpty,
      );
    },
  );

  testWidgets('UNKNOWN role falls back to SYSTEM rendering', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChatBubble(
          message: _msg(role: ChatRole.unknown, text: 'mystery'),
        ),
      ),
    );

    expect(find.text('mystery'), findsOneWidget);
    final txt = tester.widget<Text>(find.text('mystery'));
    expect(txt.style?.fontStyle, FontStyle.italic);
  });

  testWidgets(
    'long text does not overflow (wraps within 75% width constraint)',
    (tester) async {
      // 1500 chars of single-line text — more than fits on any phone.
      final long = 'lorem ipsum ' * 130;
      await tester.pumpWidget(
        _wrap(ChatBubble(message: _msg(role: ChatRole.user, text: long))),
      );
      // Pump should complete without a RenderFlex/overflow exception.
      expect(tester.takeException(), isNull);
      // The Text is laid out (found exactly once).
      expect(find.byType(Text), findsOneWidget);
    },
  );
}
