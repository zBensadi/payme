import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();

  ConnectivityService({Connectivity? connectivity}) 
      : _connectivity = connectivity ?? Connectivity() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isConnected = results.any((result) => 
        result != ConnectivityResult.none
      );
      _controller.add(isConnected);
    });
  }

  Stream<bool> get isConnected => _controller.stream;

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
  
  void dispose() {
    _controller.close();
  }
}
