import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return _hasConnection(result);
  }

  static Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map(_hasConnection);
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
