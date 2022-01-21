import 'dart:convert';
import 'dart:typed_data';

import 'package:walletconnect_dart/src/exceptions/exceptions.dart';
import 'package:walletconnect_dart/src/providers/wallet_connect_provider.dart';
import 'package:walletconnect_dart/src/walletconnect.dart';

/// A provider implementation to easily support the Algorand blockchain.
class AlgorandWCProvider extends WalletConnectProvider {
  AlgorandWCProvider(WalletConnect connector) : super(connector: connector);

  /// Signs an unsigned transaction by sending a request to the wallet.
  /// Returns the signed transaction bytes.
  /// Throws [WalletConnectException] if unable to sign the transaction.
  @override
  Future<List<Uint8List>> signTransaction({
    required Uint8List transaction,
    Map<String, dynamic> params = const {},
  }) async {
    final txToSign = {
      'txn': base64Encode(transaction),
      ...params,
    };

    return _signTransactions(requestParams: [txToSign]);
  }

  /// Signs unsigned transactions by sending a request to the wallet.
  /// Returns the signed transactions bytes.
  /// Throws [WalletConnectException] if unable to sign the transactions.
  @override
  Future<List<Uint8List>> signTransactions({
    required List<Uint8List> transactions,
    Map<String, dynamic> params = const {},
  }) async {
    final txsToSign = transactions
        .map((tx) => {
              'txn': base64Encode(tx),
              ...params,
            })
        .toList();

    return _signTransactions(requestParams: txsToSign);
  }

  /// Signs unsigned transactions by sending a request to the wallet.
  /// Returns the signed transactions bytes.
  /// Throws [WalletConnectException] if unable to sign the transactions.
  Future<List<Uint8List>> _signTransactions({
    required List<Map<String, dynamic>> requestParams,
  }) async {
    final result = await connector.sendCustomRequest(
      method: 'algo_signTxn',
      params: [requestParams],
    );

    if (result == null || result is! List) {
      throw WalletConnectException('Unable to sign transaction');
    }

    return result.map((tx) => Uint8List.fromList(List<int>.from(tx))).toList();
  }

  /// The chain id of the Algorand blockchain.
  @override
  String get chainId => '4160';
}
