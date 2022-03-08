import 'package:json_annotation/json_annotation.dart';

class ChainIdConverter implements JsonConverter<String?, dynamic> {
  const ChainIdConverter();

  @override
  String? fromJson(dynamic json) {
    if (json is num) {
      return json.toString();
    }

    if (json is String) {
      return json;
    }

    return null;
  }

  @override
  String? toJson(String? chainId) {
    return chainId ?? '';
  }
}
