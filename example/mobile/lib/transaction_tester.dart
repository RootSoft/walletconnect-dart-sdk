import 'package:walletconnect_dart/walletconnect_dart.dart';

abstract class TransactionTester {
  TransactionTester()
      : connector = WalletConnect(
          bridge: 'https://bridge.walletconnect.org',
          clientMeta: PeerMeta(
            name: 'WalletConnect',
            description: 'WalletConnect Developer App',
            url: 'https://walletconnect.org',
            icons: [
              'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
            ],
          ),
        );

  final WalletConnect connector;

  Future<String> signTransaction(SessionStatus session);

  Future<String> signTransactions(SessionStatus session);

  Future<SessionStatus> connect({OnDisplayUriCallback? onDisplayUri});

  Future<void> disconnect();
}
