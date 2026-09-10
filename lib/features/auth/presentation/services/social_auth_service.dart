import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:enterprise_flutter_app/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class SocialAuthorizationResult {
  const SocialAuthorizationResult({
    required this.authorizationCode,
    required this.codeVerifier,
    required this.redirectUri,
    required this.clientId,
  });

  final String authorizationCode;
  final String codeVerifier;
  final String redirectUri;
  final String clientId;
}

class SocialAuthException implements Exception {
  const SocialAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Owns the browser leg of the backend OAuth flow. Google credentials remain
/// server-side; this app only knows its registered OAuth client and callback.
class SocialAuthService {
  const SocialAuthService(this._config);

  final AppConfig _config;

  Future<SocialAuthorizationResult> authenticateGoogle() async {
    final clientId = dotenv.env['SOCIAL_OAUTH_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      throw const SocialAuthException(
        'Google sign-in is not configured for this environment.',
      );
    }

    final redirectUri = _redirectUri();
    final verifier = _randomUrlSafeValue();
    final state = _randomUrlSafeValue();
    final challenge = base64Url
        .encode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');
    final loginUri =
        Uri.parse(_config.baseUrl).resolve('/auth/social/google/login').replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid profile email offline_access',
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );

    final resultUri = Uri.parse(
      await FlutterWebAuth2.authenticate(
        url: loginUri.toString(),
        callbackUrlScheme: Uri.parse(redirectUri).scheme,
      ),
    );
    if (resultUri.toString().split('?').first != redirectUri) {
      throw const SocialAuthException('Unexpected OAuth callback destination.');
    }
    if (resultUri.queryParameters['state'] != state) {
      throw const SocialAuthException(
        'Google sign-in state could not be verified.',
      );
    }
    final error = resultUri.queryParameters['error'];
    if (error != null) {
      throw SocialAuthException('Google sign-in failed: $error');
    }
    final code = resultUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const SocialAuthException(
        'Google sign-in did not return an authorization code.',
      );
    }
    return SocialAuthorizationResult(
      authorizationCode: code,
      codeVerifier: verifier,
      redirectUri: redirectUri,
      clientId: clientId,
    );
  }

  String _redirectUri() {
    if (kIsWeb) {
      return dotenv.env['SOCIAL_WEB_REDIRECT_URI'] ??
          Uri.base.resolve('auth.html').toString();
    }
    return dotenv.env['SOCIAL_NATIVE_REDIRECT_URI'] ??
        'enterprise-flutter-app://auth/callback';
  }

  String _randomUrlSafeValue() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
