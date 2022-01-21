import 'dart:typed_data';

import 'package:algorand_dart/algorand_dart.dart' as algorand;
import 'package:convert/convert.dart';
import 'package:http/http.dart';
import 'package:mobile_dapp/transaction_tester.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/src/crypto/secp256k1.dart';
import 'package:web3dart/web3dart.dart';

class WalletConnectEthereumCredentials extends CustomTransactionSender {
  WalletConnectEthereumCredentials({required this.provider});

  final EthereumWalletConnectProvider provider;
  @override
  Future<EthereumAddress> extractAddress() {
    // TODO: implement extractAddress
    throw UnimplementedError();
  }

  @override
  Future<String> sendTransaction(Transaction transaction) async {
    final hash = await provider.sendTransaction(
      from: transaction.from!.hex,
      to: transaction.to?.hex,
      data: transaction.data,
      gas: transaction.maxGas,
      gasPrice: transaction.gasPrice?.getInWei,
      value: transaction.value?.getInWei,
      nonce: transaction.nonce,
    );
    return '';
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    // TODO: implement signToSignature
    throw UnimplementedError();
  }
}

class EthereumTransactionTester extends TransactionTester {
  final Web3Client ethereum;

  EthereumTransactionTester._internal({
    required this.ethereum,
  });

  factory EthereumTransactionTester() {
    final ethereum = Web3Client('https://ropsten.infura.io/', Client());

    return EthereumTransactionTester._internal(ethereum: ethereum);
  }

  @override
  Future<SessionStatus> connect({OnDisplayUriCallback? onDisplayUri}) async {
    return connector.connect(chainId: 3, onDisplayUri: onDisplayUri);
  }

  @override
  Future<void> disconnect() async {
    await connector.killSession();
  }

  @override
  Future<String> signTransaction(SessionStatus session) async {
    final sender = EthereumAddress.fromHex(session.accounts[0]);

    final transaction = Transaction(
      to: sender,
      from: sender,
      gasPrice: EtherAmount.inWei(BigInt.one),
      maxGas: 100000,
      value: EtherAmount.fromUnitAndValue(EtherUnit.finney, 1),
    );

    final credentials =
        WalletConnectEthereumCredentials(provider: connector.eth!);

    // Sign the transaction
    final txBytes = await ethereum.sendTransaction(credentials, transaction);

    // Kill the session
    connector.killSession();

    return '';
  }

  @override
  Future<String> signTransactions(SessionStatus session) {
    // TODO: implement signTransactions
    throw UnimplementedError();
  }
}
