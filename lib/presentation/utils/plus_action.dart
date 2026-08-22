import 'package:flutter/material.dart';
import '../../app.dart';
import 'plus_action_registry.dart';

/// Handles [PlusIntent] by delegating to the [PlusActionRegistry].
///
/// The registry holds the callback registered by whichever screen is
/// currently visible and has a "+" FAB. If no screen has registered
/// (e.g. Dashboard), [isEnabled] returns false and the shortcut is a no-op.
class PlusAction extends Action<PlusIntent> {
  final PlusActionRegistry registry;

  PlusAction(this.registry);

  @override
  bool isEnabled(PlusIntent intent) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final hasEditableAncestor =
        primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;

    // [PLUS-KEY-DIAGNOSTIC] Step 2 — isEnabled
    debugPrint(
      '[PLUS-ACTION][isEnabled] '
      'hasEditableAncestor=$hasEditableAncestor '
      'hasActiveAction=${registry.hasActiveAction} '
      'activeScreen=${registry.activeScreenName} '
      'result=${!hasEditableAncestor && registry.hasActiveAction}',
    );

    if (hasEditableAncestor) return false;
    return registry.hasActiveAction;
  }

  @override
  Object? invoke(PlusIntent intent) {
    // [PLUS-KEY-DIAGNOSTIC] Step 3 — invoke
    debugPrint('[PLUS-ACTION][invoke] activeScreenAction=${registry.activeScreenName}');
    registry.invoke();
    return null;
  }
}
