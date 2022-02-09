<p align="center"> 
<img src="https://eidoohelp.zendesk.com/hc/article_attachments/360071262952/mceclip0.png">
</p>

[![pub.dev][pub-dev-shield]][pub-dev-url]
[![Effective Dart][effective-dart-shield]][effective-dart-url]
[![Stars][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

WalletConnect is an open source protocol for connecting decentralised applications to mobile wallets
with QR code scanning or deep linking. A user can interact securely with any Dapp from their mobile
phone, making WalletConnect wallets a safer choice compared to desktop or browser extension wallets.

## Introduction
WalletConnect connects mobile & web applications to supported mobile wallets. The WalletConnect session is started by scanning a QR code (desktop) or by clicking an application deep link (mobile).

WalletConnect-Dart-SDK is a community SDK and port of the official WalletConnect-monorepo.

WalletConnect-Dart currently supports:
* Algorand
* Ethereum

You can easily add your own network by extending from `WalletConnectProvider` and implementing the required methods using `sendCustomRequest`.
An example from Binance Smart Chain can be found [here](https://docs.binance.org/walletconnect.html).
For more information regarding the implementation, check out `EthereumWalletConnectProvider` and `AlgorandWalletConnectProvider`.

**WalletConnect lets you build:**
- Decentralized web applications and display QR codes with [qr_flutter](https://pub.dev/packages/qr_flutter)
- Mobile dApps with deep linking using [url_launcher](https://pub.dev/packages/url_launcher)
- Cross-platform wallets

Once installed, you can simply connect your application to a wallet.

```dart
// Create a connector
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
```

## Usage

### Dapps

**Initiate connection**

```dart
// Create a connector
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

// Subscribe to events
connector.on('connect', (session) => print(session));
connector.on('session_update', (payload) => print(payload));
connector.on('disconnect', (session) => print(session));

// Create a new session
if (!connector.connected) {
    final session = await connector.createSession(
        chainId: 4160,
        onDisplayUri: (uri) => print(uri),
    );
}
```

**Sign transaction**

```dart
final sender = Address.fromAlgorandAddress(address: session.accounts[0]);

// Fetch the suggested transaction params
final params = await algorand.getSuggestedTransactionParams();

// Build the transaction
final tx = await (PaymentTransactionBuilder()
  ..sender = sender
  ..noteText = 'Signed with WalletConnect'
  ..amount = Algo.toMicroAlgos(0.0001)
  ..receiver = sender
  ..suggestedParams = params)
    .build();

// Sign the transaction
final signedBytes = await provider.signTransaction(
    tx.toBytes(),
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
```

### Wallets

**Initiate connection**

```dart
// Create a connector
final connector = WalletConnect(
    uri: 'wc:8a5e5bdc-a0e4-47...TJRNmhWJmoxdFo6UDk2WlhaOyQ5N0U=',
    clientMeta: PeerMeta(
      name: 'WalletConnect',
      description: 'WalletConnect Developer App',
      url: 'https://walletconnect.org',
      icons: [
        'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
      ],
    ),
);

// Subscribe to events
connector.on('connect', (session) => print(session));
connector.on('session_request', (payload) => print(payload));
connector.on('disconnect', (session) => print(session));
```

**Manage connection**

```dart
// Approve session
await connector.approveSession(chainId: 4160, accounts: ['0x4292...931B3']);

// Reject session
await connector.rejectSession(message: 'Optional error message');

// Update session
await connector.updateSession(SessionStatus(chainId: 4000, accounts: ['0x4292...931B3']));
```

**Kill session**

```dart
await connector.killSession();
```

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Contributing & Pull Requests
Feel free to send pull requests.

Please see [CONTRIBUTING](.github/CONTRIBUTING.md) for details.

## Credits

- [Tomas Verhelst](https://github.com/rootsoft)
- [Tom Friml](https://github.com/3ph)  
- [All Contributors](../../contributors)

## License

The MIT License (MIT). Please see [License File](LICENSE.md) for more information.


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[pub-dev-shield]: https://img.shields.io/pub/v/walletconnect_dart?style=for-the-badge
[pub-dev-url]: https://pub.dev/packages/walletconnect_dart
[effective-dart-shield]: https://img.shields.io/badge/style-effective_dart-40c4ff.svg?style=for-the-badge
[effective-dart-url]: https://github.com/tenhobi/effective_dart
[stars-shield]: https://img.shields.io/github/stars/rootsoft/walletconnect-dart-sdk.svg?style=for-the-badge&logo=github&colorB=deeppink&label=stars
[stars-url]: https://packagist.org/packages/rootsoft/walletconnect-dart-sdk
[issues-shield]: https://img.shields.io/github/issues/rootsoft/walletconnect-dart-sdk.svg?style=for-the-badge
[issues-url]: https://github.com/rootsoft/walletconnect-dart-sdk/issues
[license-shield]: https://img.shields.io/github/license/rootsoft/walletconnect-dart-sdk.svg?style=for-the-badge
[license-url]: https://github.com/RootSoft/walletconnect-dart-sdk/blob/master/LICENSE