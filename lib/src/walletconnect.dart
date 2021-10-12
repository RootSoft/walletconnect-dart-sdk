import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:stack_trace/stack_trace.dart';
import 'package:uuid/uuid.dart';
import 'package:walletconnect/src/api/api.dart';
import 'package:walletconnect/src/crypto/cipher_box.dart';
import 'package:walletconnect/src/crypto/crypto.dart';
import 'package:walletconnect/src/crypto/encrypted_payload.dart';
import 'package:walletconnect/src/exceptions/exceptions.dart';
import 'package:walletconnect/src/network/network.dart';
import 'package:walletconnect/src/providers/providers.dart';
import 'package:walletconnect/src/providers/wallet_connect_provider.dart';
import 'package:walletconnect/src/session/session.dart';
import 'package:walletconnect/src/utils/bridge_utils.dart';
import 'package:walletconnect/src/utils/event.dart';
import 'package:walletconnect/src/utils/event_bus.dart';

const ethSigningMethods = [
  'eth_sendTransaction',
  'eth_signTransaction',
  'eth_sign',
  'eth_signTypedData',
  'eth_signTypedData_v1',
  'eth_signTypedData_v2',
  'eth_signTypedData_v3',
  'eth_signTypedData_v4',
  'personal_sign',
];

typedef OnConnectRequest = void Function(SessionStatus status);
typedef OnSessionUpdate = void Function(WCSessionUpdateResponse response);
typedef OnDisconnect = void Function();
typedef OnDisplayUriCallback = void Function(String uri);

class WalletConnect {
  /// The wallet connect protocol
  static const protocol = 'wc';

  /// The current wallet connect version
  static const version = 1;

  /// The current active session.
  final WalletConnectSession session;

  final SessionStorage? sessionStorage;

  final List<String> signingMethods;

  SocketTransport transport;

  CipherBox cipherBox;

  WalletConnectProvider? provider;

  /// The map of request ids to pending requests.
  final _pendingRequests = <int, _Request>{};

  /// Eventbus used for internal events.
  final EventBus _eventBus;

  WalletConnect._internal({
    required this.session,
    required this.sessionStorage,
    required this.signingMethods,
    required this.cipherBox,
    required this.transport,
  }) : _eventBus = EventBus() {
    provider = AlgorandWCProvider(this);
    // Init transport event handling
    _initTransport();

    // Subscribe to internal events
    _subscribeToInternalEvents();

    if (session.handshakeTopic.isNotEmpty) {
      transport.subscribe(topic: session.handshakeTopic);
    }
  }

  factory WalletConnect({
    String bridge = '',
    String uri = '',
    WalletConnectSession? session,
    SessionStorage? sessionStorage,
    CipherBox? cipher,
    SocketTransport? transport,
    String? clientId,
    PeerMeta? clientMeta,
  }) {
    if (bridge.isEmpty && uri.isEmpty && session == null) {
      throw WalletConnectException(
        'Missing one of the required parameters: bridge / uri / session',
      );
    }

    if (bridge.isNotEmpty) {
      bridge = BridgeUtils.getBridgeUrl(bridge);
    }

    if (uri.isNotEmpty) {
      session = WalletConnectSession.fromUri(uri);
    }

    session = session ?? WalletConnectSession(bridge: bridge, accounts: []);
    session.clientId = clientId ?? const Uuid().v4();
    session.clientMeta = clientMeta ?? const PeerMeta();

    cipher = cipher ?? WalletConnectCipher();

    transport = transport ??
        SocketTransport(
          protocol: session.protocol,
          version: session.version,
          url: session.bridge,
          subscriptions: [session.clientId],
        );

    return WalletConnect._internal(
      session: session,
      sessionStorage: sessionStorage ?? SessionStorage(),
      cipherBox: cipher,
      signingMethods: [...ethSigningMethods],
      transport: transport,
    );
  }

  /// Listen to internal events.
  void on<T>(String eventName, OnEvent<T> callback) {
    _eventBus
        .on<Event<T>>()
        .where((event) => event.name == eventName)
        .listen((event) => callback(event.data));
  }

  /// Create a new session.
  Future<SessionStatus> connect({int? chainId}) async {
    if (connected) {
      return SessionStatus(
        chainId: session.chainId,
        accounts: session.accounts,
      );
    }

    return await createSession(chainId: chainId);
  }

  /// Create a new session between the dApp and wallet.
  Future<SessionStatus> createSession({
    int? chainId,
    OnDisplayUriCallback? onDisplayUri,
  }) async {
    if (connected) {
      throw WalletConnectException('Session currently connected');
    }

    // Generate encryption key
    session.key = await cipherBox.generateKey();

    final request = JsonRpcRequest(
      id: payloadId,
      method: 'wc_sessionRequest',
      params: [
        {
          'peerId': session.clientId,
          'peerMeta': session.clientMeta,
          'chainId': chainId,
        }
      ],
    );

    session.handshakeId = request.id;
    session.handshakeTopic = const Uuid().v4();

    // Display the URI
    final uri = session.toUri();
    onDisplayUri?.call(uri);
    _eventBus.fire(Event<String>('display_uri', uri));

    // Send the request
    final response = await _sendRequest(request, topic: session.handshakeTopic);

    // Notify listeners
    _handleSessionResponse(response);

    return WCSessionRequestResponse.fromJson(response).status;
  }

  /// Approve the session.
  Future approveSession({
    required List<String> accounts,
    required int chainId,
  }) async {
    if (connected) {
      throw WalletConnectException('Session currently connected');
    }

    final params = {
      'approved': true,
      'chainId': chainId,
      'networkId': 0,
      'accounts': accounts,
      'rpcUrl': '',
      'peerId': session.clientId,
      'peerMeta': session.clientMeta,
    };

    final response = JsonRpcResponse(
      id: session.handshakeId,
      result: params,
    );

    await _sendResponse(response);
    session.connected = true;

    // Notify listeners
    _eventBus.fire(Event<SessionStatus>(
      'connect',
      SessionStatus(
        chainId: chainId,
        accounts: accounts,
      ),
    ));
  }

  /// Reject the session.
  Future rejectSession({String? message}) async {
    if (connected) {
      throw WalletConnectException('Session currently connected');
    }

    message = message ?? 'Session Rejected';

    final response = JsonRpcResponse(
      id: session.handshakeId,
      error: {
        'code': -32000,
        'message': message,
      },
    );

    await _sendResponse(response);
    session.connected = false;

    // Notify listeners
    _eventBus.fire(Event<String>('disconnect', message));
  }

  /// Update the existing session.
  Future updateSession(SessionStatus sessionStatus) async {
    if (!connected) {
      throw WalletConnectException('Session currently disconnected');
    }

    session.chainId = sessionStatus.chainId;
    session.accounts = sessionStatus.accounts;
    session.networkId = sessionStatus.networkId ?? 0;
    session.rpcUrl = sessionStatus.rpcUrl ?? '';

    final params = {
      'approved': true,
      'chainId': session.chainId,
      'networkId': session.networkId,
      'accounts': session.accounts,
      'rpcUrl': session.rpcUrl,
    };

    final request = JsonRpcRequest(
      id: payloadId,
      method: 'wc_sessionUpdate',
      params: [params],
    );

    // Send the request
    final response = await _sendRequest(request);

    // Notify listeners
    _handleSessionResponse(response);
  }

  /// Send a custom request.
  Future sendCustomRequest({
    required String method,
    required List<dynamic> params,
    String? topic,
  }) async {
    final request = JsonRpcRequest(
      id: payloadId,
      method: method,
      params: params,
    );

    return _sendRequest(request);
  }

  /// Kill the current session.
  Future killSession({String? sessionError}) async {
    final message = sessionError ?? 'Session disconnected';

    final request = JsonRpcRequest(
      id: payloadId,
      method: 'wc_sessionUpdate',
      params: [
        {
          'approved': false,
          'chainId': null,
          'networkId': null,
          'accounts': null,
        }
      ],
    );

    await _sendRequest(request);

    _handleSessionDisconnect(errorMessage: message);
  }

  /// Set the default signing provider.
  void setDefaultProvider(WalletConnectProvider provider) {
    this.provider = provider;
  }

  /// Sign a transaction.
  Future<List<Uint8List>> signTransaction(
    Uint8List transaction, {
    Map<String, dynamic> params = const {},
    WalletConnectProvider? provider,
  }) async {
    provider = provider ??
        this.provider ??
        (throw WalletConnectException('No provider specified.'));
    return provider.signTransaction(transaction: transaction, params: params);
  }

  /// Sends a JSON-RPC-2 compliant request to invoke the given [method].
  Future _sendRequest(
    JsonRpcRequest request, {
    String? topic,
  }) async {
    final key = session.key;
    if (key == null) {
      return;
    }

    final data = json.encode(request.toJson());
    final payload = await cipherBox.encrypt(
      data: Uint8List.fromList(utf8.encode(data)),
      key: key,
    );

    final method = request.method;
    final silent = isSilentPayload(request);

    // Send the request
    transport.send(
      payload: payload.toJson(),
      topic: topic ?? session.peerId,
      silent: silent,
    );

    var completer = Completer.sync();
    _pendingRequests[request.id] = _Request(method, completer, Chain.current());
    return completer.future;
  }

  Future _sendResponse(JsonRpcResponse response) async {
    final key = session.key;
    if (key == null) {
      return;
    }

    final data = json.encode(response.toJson());
    final payload = await cipherBox.encrypt(
      data: Uint8List.fromList(utf8.encode(data)),
      key: key,
    );

    // Send the request
    transport.send(
      payload: payload.toJson(),
      topic: session.peerId,
      silent: true,
    );
  }

  bool isSilentPayload(JsonRpcRequest request) {
    if (request.method.startsWith('wc_')) {
      return true;
    }

    if (signingMethods.contains(request.method)) {
      return false;
    }

    return true;
  }

  int get payloadId {
    var rng = Random();
    final date = (DateTime.now().millisecondsSinceEpoch * pow(10, 3)).toInt();
    final extra = (rng.nextDouble() * pow(10, 3)).floor();
    return date + extra;
  }

  /// Check if a current session is connected.
  bool get connected => session.connected;

  void _initTransport() {
    transport.on('message', _handleIncomingMessages);

    // Open a new connection
    transport.open();
  }

  /// Handles incoming JSON RPC requests that do not have a mapped id.
  void _subscribeToInternalEvents() {
    // Wallet received a session request.
    on<JsonRpcRequest>('wc_sessionRequest', (payload) {
      final request = WCSessionRequest.fromJson(payload.params?[0]);
      session.handshakeId = payload.id;
      session.peerId = request.peerId ?? '';
      session.peerMeta = request.peerMeta ?? const PeerMeta();

      _eventBus.fire(Event<WCSessionRequest>('session_request', request));
    });

    // Wallet received a session update.
    on<JsonRpcRequest>('wc_sessionUpdate', (payload) {
      _handleSessionResponse(payload.params?[0] ?? {});
    });
  }

  void registerListeners({
    OnConnectRequest? onConnect,
    OnSessionUpdate? onSessionUpdate,
    OnDisconnect? onDisconnect,
  }) {
    on<SessionStatus>('connect', (data) => onConnect?.call(data));
    on<WCSessionUpdateResponse>(
        'session_update', (data) => onSessionUpdate?.call(data));
    on('disconnect', (data) => onDisconnect?.call());
  }

  void _handleIncomingMessages(WebSocketMessage message) async {
    final activeTopics = [session.clientId, session.handshakeTopic];
    if (!activeTopics.contains(message.topic)) {
      return;
    }

    final key = session.key;
    if (key == null) {
      return;
    }

    // Decrypt the payload
    final encryptedPayload = EncryptedPayload.fromJson(
      json.decode(message.payload),
    );
    final payload = await cipherBox.decrypt(
      payload: encryptedPayload,
      key: key,
    );

    // Decode the data
    final data = json.decode(utf8.decode(payload));

    // Check if the incoming message is a request
    if (_isJsonRpcRequest(data)) {
      final request = JsonRpcRequest.fromJson(data);
      _eventBus.fire(Event(request.method, request));
      return;
    }

    // Handle the response
    _handleSingleResponse(data);
  }

  /// Handles a decoded response from the server after batches have been
  /// resolved.
  void _handleSingleResponse(response) {
    if (!_isResponseValid(response)) return;
    var id = response['id'];
    id = (id is String) ? int.parse(id) : id;
    var request = _pendingRequests.remove(id)!;
    if (response.containsKey('result')) {
      request.completer.complete(response['result']);
    } else {
      request.completer.completeError(
          WalletConnectException(
            response['error']['message'],
            code: response['error']['code'],
            data: response['error']['data'],
          ),
          request.chain);
    }
  }

  /// Determines whether the server's response is valid per the spec.
  bool _isJsonRpcRequest(response) {
    if (response is! Map) return false;
    if (response['jsonrpc'] != '2.0') return false;
    var id = response['id'];
    id = (id is String) ? int.parse(id) : id;
    return response.containsKey('method');
  }

  /// Determines whether the server's response is valid per the spec.
  bool _isResponseValid(response) {
    if (response is! Map) return false;
    if (response['jsonrpc'] != '2.0') return false;
    var id = response['id'];
    id = (id is String) ? int.parse(id) : id;
    if (!_pendingRequests.containsKey(id)) return false;
    if (response.containsKey('result')) return true;

    if (!response.containsKey('error')) return false;
    var error = response['error'];
    if (error is! Map) return false;
    if (error['code'] is! int) return false;
    if (error['message'] is! String) return false;
    return true;
  }

  void _handleSessionResponse(Map<String, dynamic> params) {
    final approved = params['approved'] ?? false;
    final connected = this.connected;
    if (approved && !connected) {
      // New connection
      session.approve(params);

      // Store session
      sessionStorage?.store(session);

      // Notify the listeners
      final data = WCSessionRequestResponse.fromJson(params);
      _eventBus.fire(Event<SessionStatus>('connect', data.status));
    } else if (approved && connected) {
      // Session update
      session.approve(params);

      // Store session
      sessionStorage?.store(session);

      // Notify the listeners
      final data = WCSessionUpdateResponse.fromJson(params);
      _eventBus.fire(Event<WCSessionUpdateResponse>('session_update', data));
    } else {
      _handleSessionDisconnect();
    }
  }

  void _handleSessionDisconnect({String? errorMessage}) {
    session.reset();

    // Remove storage session
    sessionStorage?.removeSession();

    // Close the web socket connection
    transport.close();

    // Notify listeners
    _eventBus.fire(Event<Map<String, dynamic>>('disconnect', {
      'message': errorMessage ?? '',
    }));
  }
}

/// A pending request to the server.
class _Request {
  /// The method that was sent.
  final String method;

  /// The completer to use to complete the response future.
  final Completer completer;

  /// The stack chain from where the request was made.
  final Chain chain;

  _Request(this.method, this.completer, this.chain);
}
