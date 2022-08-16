import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class CosmosWalletConnectProvider extends WalletConnectProvider {
  CosmosWalletConnectProvider(WalletConnect connector)
      : super(connector: connector);
}
