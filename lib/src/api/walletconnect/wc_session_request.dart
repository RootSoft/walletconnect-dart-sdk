import 'package:json_annotation/json_annotation.dart';
import 'package:walletconnect/walletconnect.dart';

part 'wc_session_request.g.dart';

@JsonSerializable()
class WCSessionRequest {
  @JsonKey(name: 'chainId')
  final int? chainId;

  @JsonKey(name: 'peerId')
  final String? peerId;

  @JsonKey(name: 'peerMeta')
  final PeerMeta? peerMeta;

  WCSessionRequest({
    required this.chainId,
    required this.peerId,
    required this.peerMeta,
  });

  factory WCSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$WCSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WCSessionRequestToJson(this);

  @override
  String toString() {
    return 'WCSessionRequest{chainId: $chainId, peerId: $peerId, peerMeta: $peerMeta}';
  }
}
