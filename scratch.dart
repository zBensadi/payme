import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState {}
class MyNotifier extends AutoDisposeNotifier<MyState> {
  @override
  MyState build() => MyState();

  void update() {
    print(state);
  }
}
