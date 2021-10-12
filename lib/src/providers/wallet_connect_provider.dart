import 'dart:typed_data';

import 'package:walletconnect_dart/src/walletconnect.dart';

abstract class WalletConnectProvider {
  final WalletConnect connector;

  WalletConnectProvider({required this.connector});

  Future<List<Uint8List>> signTransaction({
    required Uint8List transaction,
    Map<String, dynamic> params = const {},
  });

  int get chainId;
}
