import 'dart:convert';

import 'package:every_door/private.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';

class OpenStreetMapOAuth2Client extends OAuth2Client {
  OpenStreetMapOAuth2Client()
      : super(
          authorizeUrl: 'https://$kOsmAuth2Endpoint/oauth2/authorize',
          tokenUrl: 'https://$kOsmAuth2Endpoint/oauth2/token',
          redirectUri: 'everydoor:/oauth',
          customUriScheme: 'everydoor',
        );
}

class OAuthHelperError implements Exception {
  final String message;

  OAuthHelperError(this.message);

  @override
  String toString() => 'OAuthHelperError($message)';
}

class OpenStreetMapOAuthHelper {
  static const kTokenKey = 'osmToken';

  final OAuth2Client _client = OpenStreetMapOAuth2Client();
  final String _clientId = kOauthClient;
  final String _clientSecret = kOauthSecret;

  OpenStreetMapOAuthHelper();

  Future<AccessTokenResponse?> getToken([bool requestAuth = true]) async {
    var token = await _loadToken();

    if (token != null) {
      if (token.refreshNeeded()) {
        if (token.refreshToken != null) {
          token = await _refreshToken(token.refreshToken!, requestAuth);
        } else {
          if (!requestAuth) return null;
          token = await _fetchToken();
        }
      }
    } else {
      if (!requestAuth) return null;
      token = await _fetchToken();
    }

    if (!token.isValid()) {
      throw OAuthHelperError(
          'Provider error ${token.httpStatusCode}: ${token.error}: ${token.errorDescription}');
    }

    if (!token.isBearer()) {
      throw OAuthHelperError('Only Bearer tokens are supported.');
    }

    return token;
  }

  Future<AccessTokenResponse?> _loadToken() async {
    final secure = FlutterSecureStorage();
    final data = await secure.read(key: kTokenKey);
    return data == null ? null : AccessTokenResponse.fromMap(jsonDecode(data));
  }

  _saveToken(AccessTokenResponse? token) async {
    final secure = FlutterSecureStorage();
    if (token == null)
      await secure.delete(key: kTokenKey);
    else
      await secure.write(key: kTokenKey, value: jsonEncode(token.respMap));
  }

  Future<AccessTokenResponse> _fetchToken() async {
    final token = await _client.getTokenWithAuthCodeFlow(
      clientId: _clientId,
      clientSecret: _clientSecret,
      enablePKCE: true,
      // enableState: true,
      scopes: ['read_prefs', 'write_api', 'write_notes'],
    );
    if (token.isValid()) await _saveToken(token);
    return token;
  }

  Future<AccessTokenResponse> _refreshToken(String refreshToken, [bool requestAuth = true]) async {
    AccessTokenResponse token;
    try {
      token = await _client.refreshToken(refreshToken, clientId: _clientId);
    } catch (e) {
      if (!requestAuth) rethrow;
      return await _fetchToken();
    }

    if (token.isValid()) {
      if (!token.hasRefreshToken()) token.refreshToken = refreshToken;
      await _saveToken(token);
    } else {
      if (token.error == 'invalid_grant') {
        // expired
        await _saveToken(null);
        final token2 = await getToken();
        if (token2 == null)
          throw OAuthHelperError(
              'Token and refresh token expired, and could not get a fresh one.');
        token = token2;
      } else {
        throw OAuthHelperError(
            'Error refreshing a token ${token.error}: ${token.errorDescription}');
      }
    }

    return token;
  }

  Future deleteToken() async {
    final token = await _loadToken();
    print('Logging out: $token');
    if (token != null) {
      await _saveToken(null);
      await _client.revokeToken(
        token,
        clientId: _clientId,
        clientSecret: _clientSecret,
      );
    }
  }

  Future<String?> getAuthorizationValue([AccessTokenResponse? token]) async {
    if (token == null) {
      try {
        token = await getToken(false);
      } on Exception catch (e) {
        print(e);
        return null;
      }
      if (token == null) return null; // Not authorizing here
    }
    return 'Bearer ${token.accessToken}';
  }
}
