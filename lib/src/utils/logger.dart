import 'package:flutter/foundation.dart';

class Logger {
  static bool enabled = false;
  final String name;

  Logger(this.name);

  void log(dynamic value) {
    if (!enabled || !kDebugMode) {
      return;
    }
    debugPrint("WalletConnectSDK $name $value");
  }
}