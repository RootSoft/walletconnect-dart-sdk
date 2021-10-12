import 'package:walletconnect_dart/src/session/wallet_connect_session.dart';

class SessionStorage {
  final String storageId;

  SessionStorage({this.storageId = 'walletconnect'});

  WalletConnectSession? getSession() {
    return null;
  }

  void removeSession() {}

  void store(WalletConnectSession session) {}
}
