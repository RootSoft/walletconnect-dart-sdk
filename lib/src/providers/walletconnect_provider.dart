import '../walletconnect.dart';

/// A wrapper object which contains specific WalletConnect providers
abstract class WalletConnectProvider {
  final WalletConnect connector;

  WalletConnectProvider({
    required this.connector,
  });
}
