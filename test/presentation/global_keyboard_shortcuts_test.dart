import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/app.dart';
import 'package:payme/presentation/utils/plus_action.dart';
import 'package:payme/presentation/utils/plus_action_registry.dart';

void main() {
  group('PlusAction with PlusActionRegistry', () {
    late PlusActionRegistry registry;

    setUp(() => registry = PlusActionRegistry());
    tearDown(() => registry.dispose());

    testWidgets('A: invokes active registration callback', (tester) async {
      var called = false;
      registry.push('ClientList', () => called = true);
      final action = PlusAction(registry);

      action.invoke(const PlusIntent());
      expect(called, isTrue);
    });

    testWidgets('B: isEnabled=false when no registration', (tester) async {
      final action = PlusAction(registry);
      expect(action.isEnabled(const PlusIntent()), isFalse);
    });

    testWidgets('C: isEnabled=true when registration present and no EditableText focused',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Home'))));
      registry.push('ClientList', () {});
      final action = PlusAction(registry);
      expect(action.isEnabled(const PlusIntent()), isTrue);
    });

    testWidgets('D: isEnabled=false when EditableText is focused', (tester) async {
      final focusNode = FocusNode();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TextField(focusNode: focusNode)),
      ));
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      registry.push('ClientList', () {});
      final action = PlusAction(registry);
      expect(action.isEnabled(const PlusIntent()), isFalse);

      focusNode.dispose();
    });

    testWidgets('E: invoke triggers top-of-stack — stack semantics', (tester) async {
      final log = <String>[];
      registry.push('ClientList', () => log.add('client'));
      final ledgerReg = registry.push('ClientLedger', () => log.add('ledger'));

      final action = PlusAction(registry);
      action.invoke(const PlusIntent()); // triggers ledger
      ledgerReg.dispose();
      action.invoke(const PlusIntent()); // triggers client

      expect(log, ['ledger', 'client']);
    });
  });
}
