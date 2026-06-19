// lib/config/auth_sdk_config.dart
//
// Configuration for the external "Akun RG" SSO handshake.
//
// SECURITY: these values must NOT be hardcoded in source or committed to git.
// They are injected at build time via --dart-define (or --dart-define-from-file).
// A `client_secret` in particular should ideally never live in a mobile client
// at all — the correct long-term fix is for the backend to perform the OAuth
// exchange and hand the app a short-lived token. Until then, keep the secret
// out of version control and ROTATE the value that was previously committed.
//
// Example run:
//   flutter run \
//     --dart-define=AKUN_RG_CLIENT_ID=... \
//     --dart-define=AKUN_RG_CLIENT_SECRET=... \
//     --dart-define=AKUN_RG_AUTH_V1=... \
//     --dart-define=AKUN_RG_AUTH_V2=...
//
// Or with a git-ignored file:
//   flutter run --dart-define-from-file=akun_rg.env.json
class AuthSdkConfig {
  const AuthSdkConfig._();

  static const String baseUrl = String.fromEnvironment(
    'AKUN_RG_BASE_URL',
    defaultValue: 'https://akunrg.com/au/pengenalan',
  );

  static const String clientId =
      String.fromEnvironment('AKUN_RG_CLIENT_ID');
  static const String clientSecret =
      String.fromEnvironment('AKUN_RG_CLIENT_SECRET');
  static const String authV1 = String.fromEnvironment('AKUN_RG_AUTH_V1');
  static const String authV2 = String.fromEnvironment('AKUN_RG_AUTH_V2');

  static const String redirect = String.fromEnvironment(
    'AKUN_RG_REDIRECT',
    defaultValue: 'portalsi://callback',
  );
  static const String redirectFrom = String.fromEnvironment(
    'AKUN_RG_REDIRECT_FROM',
    defaultValue: 'https://portalsi.com',
  );

  /// True only when all required secrets were provided at build time.
  static bool get isConfigured =>
      clientId.isNotEmpty &&
      clientSecret.isNotEmpty &&
      authV1.isNotEmpty &&
      authV2.isNotEmpty;
}
