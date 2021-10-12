import 'dart:convert';

import 'package:walletconnect_dart/src/api/websocket/web_socket_message.dart';
import 'package:walletconnect_dart/src/utils/event.dart';
import 'package:walletconnect_dart/src/utils/event_bus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// The transport layer used to perform JSON-RPC 2 requests.
/// A client calls methods on a server and handles the server's responses to
/// those method calls. Methods can be called with [sendRequest].
class SocketTransport {
  final String protocol;
  final int version;
  final String url;
  final List<String> subscriptions;

  final EventBus _eventBus;

  WebSocketChannel? channel;

  bool _connected = false;

  SocketTransport({
    required this.protocol,
    required this.version,
    required this.url,
    required this.subscriptions,
  }) : _eventBus = EventBus();

  void open() {
    // Connect the channel
    final wsUrl = getWebSocketUrl(
      url: url,
      protocol: protocol,
      version: version.toString(),
    );
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _connected = true;

    // Queue subscriptions
    _queueSubscriptions();

    // Listen for messages
    channel?.stream.listen(_socketReceive, onError: (error) {
      _connected = false;
    }, onDone: () {
      _connected = false;
    });
  }

  /// Closes the web socket connection.
  Future close() async {
    await channel?.sink.close();
  }

  void send({
    required Map<String, dynamic> payload,
    required String topic,
    bool silent = false,
  }) async {
    final data = {
      'topic': topic,
      'type': 'pub',
      'payload': json.encode(payload),
      'silent': silent,
    };

    final message = json.encode(data);
    channel?.sink.add(message);
  }

  void subscribe({required String topic, bool silent = false}) {
    final data = {
      'topic': topic,
      'type': 'sub',
      'payload': '',
      'silent': silent,
    };

    final message = json.encode(data);
    channel?.sink.add(message);
  }

  void on<T>(String eventName, OnEvent<T> callback) {
    _eventBus
        .on<Event<T>>()
        .where((event) => event.name == eventName)
        .listen((event) => callback(event.data));
  }

  /// Check if we are currently connected with the socket.
  bool get connected => _connected;

  void _socketReceive(event) {
    if (event is! String) return;

    // TODO Check if websocket message is valid

    final data = json.decode(event);
    final message = WebSocketMessage.fromJson(data);
    _eventBus.fire(Event<WebSocketMessage>('message', message));
  }

  String getWebSocketUrl({
    required String url,
    required String protocol,
    required String version,
  }) {
    url = url.startsWith('https')
        ? url.replaceFirst('https', 'wss')
        : url.startsWith('http')
            ? url.replaceFirst('http', 'ws')
            : url;

    final splitUrl = url.split('?');

    final params = Uri.dataFromString(url).queryParameters;
    final queryParams = {
      ...params,
      'protocol': protocol,
      'version': version,
      'env': 'browser',
      'host': 'test',
    };
    final queryString = Uri(queryParameters: queryParams).query;
    return '${splitUrl[0]}?$queryString';
  }

  void _queueSubscriptions() {
    for (var topic in subscriptions) {
      subscribe(topic: topic, silent: true);
    }
  }
}
