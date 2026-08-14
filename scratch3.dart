import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState {}
class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() => MyState();
}

final myProv = NotifierProvider.autoDispose<MyNotifier, MyState>(MyNotifier.new);
