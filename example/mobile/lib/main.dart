import 'package:flutter/material.dart';
import 'package:mobile_dapp/wallet.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile dApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WalletConnect'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final wc = WalletConnector();

  String txId = '';
  String _displayUri = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _displayUri.isNotEmpty
            ? QrImage(data: _displayUri)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Click the button to connect with the Algorand Wallet',
                  ),
                  Text(
                    txId,
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Increment',
        child: const Icon(Icons.add),
        onPressed: () async {
          final session = await wc.connector.createSession(
            chainId: '4160',
            onDisplayUri: (uri) {
              // launch(uri);
              setState(() {
                _displayUri = uri;
              });
            },
          );

          final txId = await wc.signTransactions(session);
          setState(() {
            this.txId = txId;
            _displayUri = '';
          });
        },
      ),
    );
  }
}
