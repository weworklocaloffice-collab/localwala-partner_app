/// Token responses from login/registration (`tokens`) and refresh (top-level).
class AuthTokens {
  const AuthTokens({required this.access, this.refresh});

  final String access;
  final String? refresh;

  static AuthTokens? tryParse(Map<String, dynamic> response) {
    final Object? nested = response['tokens'];
    final Map<dynamic, dynamic> tokens = nested is Map ? nested : response;
    final String? access = readToken(
      tokens['access'] ?? tokens['accessToken'] ?? tokens['token'],
    );
    final Object? rawRefresh = tokens['refresh'] ?? tokens['refreshToken'];
    final String? refresh = readToken(rawRefresh);
    if (access == null || (rawRefresh != null && refresh == null)) return null;
    return AuthTokens(access: access, refresh: refresh);
  }

  /// Never stringify objects: only their `token` string is a bearer credential.
  /// Reject cached Map.toString() values left by older app versions too.
  static String? readToken(Object? value) {
    if (value is Map) value = value['token'];
    if (value is! String) return null;
    final String token = value.trim();
    if (token.isEmpty ||
        token.startsWith('{') ||
        token.startsWith('[') ||
        RegExp(r'\s').hasMatch(token)) {
      return null;
    }
    return token;
  }
}
