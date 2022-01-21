import 'package:algorand_dart/algorand_dart.dart';
import 'package:mobile_dapp/transaction_tester.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class AlgorandTransactionTester extends TransactionTester {
  final Algorand algorand;

  AlgorandTransactionTester._internal({
    required this.algorand,
  });

  factory AlgorandTransactionTester() {
    final algorand = Algorand(
      algodClient: AlgodClient(apiUrl: AlgoExplorer.TESTNET_ALGOD_API_URL),
    );

    return AlgorandTransactionTester._internal(algorand: algorand);
  }

  @override
  Future<SessionStatus> connect({OnDisplayUriCallback? onDisplayUri}) async {
    return connector.connect(chainId: 4160, onDisplayUri: onDisplayUri);
  }

  @override
  Future<void> disconnect() async {
    await connector.killSession();
  }

  @override
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
    final signedBytes = await connector.algo?.signTransaction(
      txBytes,
      params: {
        'message': 'Optional description message',
      },
    );

    if (signedBytes == null) return '';

    // Broadcast the transaction
    final txId = await algorand.sendRawTransactions(
      signedBytes,
      waitForConfirmation: true,
    );

    // Kill the session
    connector.killSession();

    return txId;
  }

  @override
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
    final signedBytes = await connector.algo?.signTransactions(
      [tx1Bytes, tx2Bytes],
      params: {
        'message': 'Optional description message',
      },
    );

    if (signedBytes == null) return '';

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
