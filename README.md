<p align="center"> 
<img src="https://eidoohelp.zendesk.com/hc/article_attachments/360071262952/mceclip0.png">
</p>

# walletconnect-dart-sdk
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

> :warning: At the moment, only [Algorand](https://www.algorand.com/) is supported!

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
// Set a default walletconnect provider
connector.setDefaultProvider(AlgorandWCProvider(connector));

// Sign the transaction
final txBytes = Encoder.encodeMessagePack(transaction.toMessagePack());
final signedBytes = await connector.signTransaction(
    txBytes,
    params: {
      'message': 'Optional description message',
    },
);
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