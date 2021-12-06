import 'package:walletconnect_dart/src/session/wallet_connect_session.dart';

abstract class SessionStorage {
  Future store(WalletConnectSession session);

  Future<WalletConnectSession?> getSession();

  Future removeSession();
}
