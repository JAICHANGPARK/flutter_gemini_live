// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Auth & Ephemeral Tokens
// ============================================================================

/// Ephemeral authentication token representation.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class AuthToken {
  /// The resource name of the auth token (e.g. `auth_tokens/...`).
  final String? name;

  /// Optional time after which messages in Live API sessions will be rejected.
  final String? expireTime;

  /// Optional time after which new Live API sessions using this token will be rejected.
  final String? newSessionExpireTime;

  /// Optional number of times the token can be used (0 = unlimited, default = 1).
  final int? uses;

  AuthToken({
    this.name,
    this.expireTime,
    this.newSessionExpireTime,
    this.uses,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    final parsed = _$AuthTokenFromJson(json);
    return AuthToken(
      name: parsed.name,
      expireTime: parsed.expireTime ?? json['expireTime'] as String?,
      newSessionExpireTime: parsed.newSessionExpireTime ??
          json['newSessionExpireTime'] as String?,
      uses: parsed.uses,
    );
  }

  Map<String, dynamic> toJson() => _$AuthTokenToJson(this);
}

/// Configuration constraints locked in the ephemeral token for Live API connections.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class LiveConnectConstraints {
  /// ID of the model to configure in the ephemeral token for Live API.
  final String? model;

  /// Configuration specific to Live API connections created using this token.
  final GenerationConfig? config;

  LiveConnectConstraints({this.model, this.config});

  factory LiveConnectConstraints.fromJson(Map<String, dynamic> json) =>
      _$LiveConnectConstraintsFromJson(json);

  Map<String, dynamic> toJson() => _$LiveConnectConstraintsToJson(this);
}

/// Configuration parameters for creating an ephemeral authentication token.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class CreateAuthTokenConfig {
  /// Optional time after which messages in Live API sessions will be rejected.
  final String? expireTime;

  /// Optional time after which new Live API sessions using this token will be rejected.
  final String? newSessionExpireTime;

  /// Optional number of times the token can be used.
  final int? uses;

  /// Configuration specific to Live API connections created using this token.
  final LiveConnectConstraints? liveConnectConstraints;

  /// Additional fields to lock in the effective LiveConnectParameters.
  final List<String>? lockAdditionalFields;

  CreateAuthTokenConfig({
    this.expireTime,
    this.newSessionExpireTime,
    this.uses,
    this.liveConnectConstraints,
    this.lockAdditionalFields,
  });

  factory CreateAuthTokenConfig.fromJson(Map<String, dynamic> json) =>
      _$CreateAuthTokenConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAuthTokenConfigToJson(this);
}

