import 'package:algorand_dart/algorand_dart.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class WalletConnector {
  final Algorand algorand;
  final WalletConnect connector;

  const WalletConnector._internal({
    required this.algorand,
    required this.connector,
  });

  factory WalletConnector() {
    final algorand = Algorand(
      algodClient: AlgodClient(apiUrl: AlgoExplorer.TESTNET_ALGOD_API_URL),
    );

    final connector = WalletConnect(
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

    connector.setDefaultProvider(AlgorandWCProvider(connector));

    return WalletConnector._internal(algorand: algorand, connector: connector);
  }

  Future<String> signTransaction(SessionStatus session) async {
    final sender = Address.fromAlgorandAddress(address: session.accounts[0]);

    // Fetch the suggested transaction params
    final params = await algorand.getSuggestedTransactionParams();

    // Build the transaction
    final transaction = await (PaymentTransactionBuilder()
          ..sender = sender
          ..noteText = 'Signed with WalletConnect'
          ..amount = Algo.toMicroAlgos(0.0001)
          ..receiver = sender
          ..suggestedParams = params)
        .build();

    // Sign the transaction
    final txBytes = Encoder.encodeMessagePack(transaction.toMessagePack());
    final signedBytes = await connector.signTransaction(
      txBytes,
      params: {
        'message': 'Optional description message',
      },
    );

    // Broadcast the transaction
    final txId = await algorand.sendRawTransactions(
      signedBytes,
      waitForConfirmation: true,
    );

    // Kill the session
    connector.killSession();

    return txId;
  }

  Future<String> signTransactions(SessionStatus session) async {
    final sender = Address.fromAlgorandAddress(address: session.accounts[0]);

    // Fetch the suggested transaction params
    final params = await algorand.getSuggestedTransactionParams();

    // Build the transaction
    final transaction1 = await (PaymentTransactionBuilder()
          ..sender = sender
          ..noteText = 'Signed with WalletConnect - 1'
          ..amount = Algo.toMicroAlgos(0.0001)
          ..receiver = sender
          ..suggestedParams = params)
        .build();
    final transaction2 = await (PaymentTransactionBuilder()
          ..sender = sender
          ..noteText = 'Signed with WalletConnect - 2'
          ..amount = Algo.toMicroAlgos(0.0002)
          ..receiver = sender
          ..suggestedParams = params)
        .build();
    AtomicTransfer.group([transaction1, transaction2]);

    // Sign the transaction
    final tx1Bytes = Encoder.encodeMessagePack(transaction1.toMessagePack());
    final tx2Bytes = Encoder.encodeMessagePack(transaction2.toMessagePack());
    final signedBytes = await connector.signTransactions(
      [tx1Bytes, tx2Bytes],
      params: {
        'message': 'Optional description message',
      },
    );

    // Broadcast the transaction
    final txId = await algorand.sendRawTransactions(
      signedBytes,
      waitForConfirmation: true,
    );

    // Kill the session
    connector.killSession();

    return txId;
  }
}
