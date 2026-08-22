import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A screen pushes its creation callback when it becomes active and
/// receives back a [PlusActionRegistration] token. Calling
/// [PlusActionRegistration.dispose] removes that registration from the stack.
///
/// The registry always invokes the **top-of-stack** callback, which
/// naturally follows GoRouter push/pop navigation order: when a child screen
/// is pushed it becomes the active registrant, and when it is popped its
/// parent is restored.
class PlusActionRegistry extends ChangeNotifier {
  final List<_PlusRegistration> _stack = [];

  /// Registers [callback] as the active creation action for [screenName].
  ///
  /// Returns a [PlusActionRegistration] token. The caller MUST call
  /// [PlusActionRegistration.dispose] in its [State.dispose] method.
  PlusActionRegistration push(String screenName, VoidCallback callback) {
    final reg = _PlusRegistration(screenName, callback);
    _stack.add(reg);
    notifyListeners();
    debugPrint('[PLUS-ACTION] registered screenName=$screenName  stackDepth=${_stack.length}');
    return PlusActionRegistration._(this, reg);
  }

  void _pop(_PlusRegistration reg) {
    final removed = _stack.remove(reg);
    if (removed) {
      notifyListeners();
      debugPrint('[PLUS-ACTION] unregistered screenName=${reg.screenName}  stackDepth=${_stack.length}');
    }
  }

  /// Whether any screen has an active registration.
  bool get hasActiveAction => _stack.isNotEmpty;

  /// Human-readable name of the currently active screen, for diagnostics.
  String? get activeScreenName => _stack.isEmpty ? null : _stack.last.screenName;

  /// Invokes the active (top-of-stack) callback.
  void invoke() {
    if (_stack.isNotEmpty) {
      debugPrint('[PLUS-ACTION] invoke  activeScreenAction=${_stack.last.screenName}');
      _stack.last.callback();
    }
  }
}

class _PlusRegistration {
  final String screenName;
  final VoidCallback callback;
  _PlusRegistration(this.screenName, this.callback);
}

/// Opaque token returned by [PlusActionRegistry.push].
/// Call [dispose] in your [State.dispose] to unregister.
class PlusActionRegistration {
  final PlusActionRegistry _registry;
  final _PlusRegistration _reg;
  bool _disposed = false;

  PlusActionRegistration._(this._registry, this._reg);

  /// Idempotent — safe to call multiple times.
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _registry._pop(_reg);
    }
  }
}

/// Riverpod provider. Exposed as a [Provider] so it is a stable singleton
/// for the lifetime of the [ProviderScope].
final plusActionRegistryProvider = Provider<PlusActionRegistry>((ref) {
  final registry = PlusActionRegistry();
  ref.onDispose(registry.dispose);
  return registry;
});
