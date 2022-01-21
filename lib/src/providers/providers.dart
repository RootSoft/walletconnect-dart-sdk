import '../providers/algorand_walletconnect_provider.dart';
import '../providers/ethereum_walletconnect_provider.dart';
import '../walletconnect.dart';

export 'algorand_walletconnect_provider.dart';
export 'ethereum_walletconnect_provider.dart';

/// A wrapper object which contains specific WalletConnect providers
class WalletConnectProviders {
  WalletConnectProviders({
    required WalletConnect connector,
    AlgorandWalletConnectProvider? algorandProvider,
    EthereumWalletConnectProvider? ethereumProvider,
  })  : algo = algorandProvider ?? AlgorandWalletConnectProvider(connector),
        eth = ethereumProvider ?? EthereumWalletConnectProvider(connector);

  late final AlgorandWalletConnectProvider algo;
  late final EthereumWalletConnectProvider eth;
}
