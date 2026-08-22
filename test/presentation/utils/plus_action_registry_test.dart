import 'package:flutter_test/flutter_test.dart';
import 'package:payme/presentation/utils/plus_action_registry.dart';

void main() {
  group('PlusActionRegistry', () {
    late PlusActionRegistry registry;

    setUp(() => registry = PlusActionRegistry());
    tearDown(() => registry.dispose());

    // ─── A. Single registration ───────────────────────────────────────────────
    test('A: push/invoke — single callback is invoked', () {
      var called = false;
      registry.push('TestScreen', () => called = true);

      expect(registry.hasActiveAction, isTrue);
      expect(registry.activeScreenName, 'TestScreen');

      registry.invoke();
      expect(called, isTrue);
    });

    // ─── B. Stack order ───────────────────────────────────────────────────────
    test('B: stack order — top-of-stack callback is invoked', () {
      final log = <String>[];
      registry.push('Bottom', () => log.add('bottom'));
      registry.push('Top', () => log.add('top'));

      registry.invoke();
      expect(log, ['top'], reason: 'Only the top registration should fire');
      expect(registry.activeScreenName, 'Top');
    });

    // ─── C. Pop restores previous ─────────────────────────────────────────────
    test('C: dispose top — previous callback becomes active', () {
      final log = <String>[];
      registry.push('Bottom', () => log.add('bottom'));
      final topToken = registry.push('Top', () => log.add('top'));

      topToken.dispose();

      expect(registry.activeScreenName, 'Bottom');
      registry.invoke();
      expect(log, ['bottom']);
    });

    // ─── D. Double-dispose is idempotent ─────────────────────────────────────
    test('D: double-dispose is safe', () {
      final token = registry.push('Screen', () {});
      expect(() {
        token.dispose();
        token.dispose(); // must not throw
      }, returnsNormally);
      expect(registry.hasActiveAction, isFalse);
    });

    // ─── E. Empty registry ────────────────────────────────────────────────────
    test('E: no registrations — hasActiveAction is false', () {
      expect(registry.hasActiveAction, isFalse);
      expect(registry.activeScreenName, isNull);
      expect(() => registry.invoke(), returnsNormally); // must not throw
    });

    // ─── F. Stale callback does not fire after dispose ────────────────────────
    test('F: dispose — stale callback does not fire', () {
      var called = false;
      final token = registry.push('Screen', () => called = true);
      token.dispose();

      registry.invoke(); // no-op — stack is empty
      expect(called, isFalse);
    });

    // ─── G. Screen change: second registration replaces first ─────────────────
    test('G: screen change — switching screens changes active action', () {
      final log = <String>[];
      final clientToken = registry.push('ClientList', () => log.add('client'));
      registry.invoke();
      expect(log, ['client']);

      // Navigate away from clients, enter invoices
      clientToken.dispose();
      registry.push('InvoiceList', () => log.add('invoice'));
      registry.invoke();
      expect(log, ['client', 'invoice']);
    });
  });
}
