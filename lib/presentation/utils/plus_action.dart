import 'package:flutter/material.dart';
import '../../app.dart';

class PlusAction extends Action<PlusIntent> {
  final VoidCallback onInvokeCallback;
  
  PlusAction(this.onInvokeCallback);

  @override
  bool isEnabled(PlusIntent intent) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    return true;
  }

  @override
  Object? invoke(PlusIntent intent) {
    onInvokeCallback();
    return null;
  }
}
