import 'dart:typed_data';

import 'package:walletconnect_dart/src/walletconnect.dart';

/// A generic interface that can be implemented to provide various provider
/// implementations.
abstract class WalletConnectProvider {
  final WalletConnect connector;

  WalletConnectProvider({required this.connector});

  /// Signs an unsigned transaction by sending a request to the wallet.
  /// Returns the signed transaction bytes.
  /// Throws [WalletConnectException] if unable to sign the transaction.
  Future<List<Uint8List>> signTransaction({
    required Uint8List transaction,
    Map<String, dynamic> params = const {},
  });

  /// Get the chain id.
  int get chainId;
}
