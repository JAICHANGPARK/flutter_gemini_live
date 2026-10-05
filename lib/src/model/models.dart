// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

part 'models/model_ids.dart';
part 'models/enums.dart';
part 'models/content.dart';
part 'models/voice.dart';
part 'models/config.dart';
part 'models/tools.dart';
part 'models/client_content.dart';
part 'models/server_content.dart';
part 'models/parameters.dart';
part 'models/auth_token.dart';
part 'models/music.dart';

Object? _computerUseFromJson(Object? json) => json;

Object? _computerUseToJson(Object? value) {
  if (value is ComputerUse) {
    return value.toJson();
  }
  return value;
}

Object? _googleMapsFromJson(Object? json) {
  if (json is Map<String, dynamic>) {
    return GoogleMaps.fromJson(json);
  }
  return json;
}

Object? _googleMapsToJson(Object? value) {
  if (value is GoogleMaps) {
    return value.toJson();
  }
  return value;
}
