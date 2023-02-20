class Logger {
  static bool enabled = false;
  final String name;

  Logger(this.name);

  void log(dynamic value) {
    if (!enabled) {
      return;
    }
    print("WalletConnectSDK $name $value");
  }
}