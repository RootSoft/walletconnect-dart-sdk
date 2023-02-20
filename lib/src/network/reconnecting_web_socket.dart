import 'dart:async';
import 'dart:math';

import 'package:walletconnect_dart/src/utils/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef OnSocketOpen = void Function(bool reconnectAttempt);
typedef OnSocketClose = void Function();
typedef OnMessage = void Function(dynamic data);

class ReconnectingWebSocket {
  /// The URL as resolved by the constructor.
  /// This is always an absolute URL. Read only.
  final String url;

  /// The number of milliseconds to delay before attempting to reconnect.
  final Duration reconnectInterval;

  /// The maximum number of milliseconds to delay a reconnection attempt.
  final Duration maxReconnectInterval;

  /// The rate of increase of the reconnect delay.
  /// Allows reconnect attempts to back off when problems persist.
  final double reconnectDecay;

  /// The maximum number of reconnection attempts to make. Unlimited if null.
  final int? maxReconnectAttempts;

  final Logger _logger = Logger((ReconnectingWebSocket).toString());

  /// The number of attempted reconnects since starting, or the last successful
  /// connection. Read only.
  int _reconnectAttempts = 0;

  /// Whether the websocket is currently connected.
  bool _connected = false;

  /// Whether the app is reconnecting.
  bool _reconnecting = false;

  /// Whether the app should try to reconnect
  bool _shouldReconnect = true;

  WebSocketChannel? _channel;

  StreamSubscription? _subscription;

  StreamSubscription? _reconnectSubscription;

  OnSocketOpen? onOpen;

  OnSocketClose? onClose;

  OnMessage? onMessage;

  ReconnectingWebSocket({
    required this.url,
    this.reconnectInterval = const Duration(milliseconds: 1000),
    this.maxReconnectInterval = const Duration(milliseconds: 30000),
    this.reconnectDecay = 1.5,
    this.maxReconnectAttempts,
    this.onOpen,
    this.onClose,
    this.onMessage,
  });

  void open(bool reconnectAttempt) {
    final maxReconnectAttempts = this.maxReconnectAttempts;
    if (reconnectAttempt) {
      if (maxReconnectAttempts != null &&
          _reconnectAttempts > maxReconnectAttempts) {
        return;
      }
    } else {
      _reconnectAttempts = 0;
    }

    _logger.log('open attempt-connect');

    // TODO migrate to IOWebSocketChannel? -> WebSocketChannel does not have
    // TODO a way to flag for ready/connection states
    // https://github.com/dart-lang/web_socket_channel/issues/25
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _onOpen(reconnectAttempt);

    // Listen for messages
    _subscription = _channel?.stream.listen(
      _onMessage,
      onError: (error) {
        _logger.log('open _subscription onError:$error');
        _onClose();
      },
      onDone: _onClose,
    );
  }

  /// Send data on the WebSocket.
  bool send(dynamic data) {
    if (!connected) {
      _logger.log('send not connected');
      return false;
    }

    try {
      _channel?.sink.add(data);
      _logger.log('send success: $data');
      return true;
    } catch (ex) {
      _logger.log('send error: $ex');
      return false;
    }
  }

  /// Closes the web socket connection.
  Future close({bool forceClose = false}) async {
    _logger.log('close force:$forceClose');
    _shouldReconnect = !forceClose;
    return _channel?.sink.close();
  }

  /// Check if the socket is currently connected.
  bool get connected => _connected;

  void _onOpen(bool reconnectAttempt) {
    _connected = true;
    _logger.log('_onOpen connected');
    _shouldReconnect = true;
    _reconnecting = false;
    onOpen?.call(reconnectAttempt);
  }

  void _onClose() {
    onClose?.call();

    if (_reconnecting) {
      _logger.log('_onClose _reconnecting');
      return;
    }

    _connected = false;

    if (!_shouldReconnect) {
      _logger.log('_onClose _shouldReconnect= false');
      return;
    }

    _reconnecting = true;

    final timeout = reconnectInterval * pow(reconnectDecay, _reconnectAttempts);
    final duration =
        timeout > maxReconnectInterval ? maxReconnectInterval : timeout;

    _logger.log('_onClose Reconnecting in: ${duration.inMilliseconds}');
    _reconnectSubscription?.cancel();
    _reconnectSubscription =
        Future.delayed(duration).asStream().listen((event) {
      _subscription?.cancel();
      _reconnectAttempts++;
      // _reconnecting = false;
      open(true);
    });
  }

  void _onMessage(event) {
    _logger.log('_onMessage ReconnectingWebSocket _onMessage, event: $event}');
    _reconnectAttempts = 0;
    onMessage?.call(event);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
