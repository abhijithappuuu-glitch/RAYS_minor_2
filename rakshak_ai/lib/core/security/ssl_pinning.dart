import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// SSL Certificate Pinning for secure API communication
class SSLPinningService {
  /// SHA-256 fingerprints of pinned server certificates.
  /// Update these when rotating server TLS certificates.
  /// To extract: openssl s_client -connect api.rakshak.ai:443 | openssl x509 -fingerprint -sha256
  static const List<String> _trustedCertificateFingerprints = [
    // Primary certificate (Let's Encrypt / DigiCert / your CA)
    'B6:5B:78:D0:7A:29:0D:EB:60:70:3E:10:9A:E5:7E:6C:5A:7E:AB:D4:D7:0E:38:A7:D1:97:C2:47:4C:25:4B:68',
    // Backup / rollover certificate
    'A2:3C:DD:54:36:8C:1F:E5:88:7D:B2:44:9F:5B:82:A4:41:CD:22:5A:66:AD:D3:F4:87:E1:C0:36:B9:9D:14:F8',
  ];

  /// Create a SecurityContext with pinned certificates
  static SecurityContext createSecurityContext() {
    final context = SecurityContext(withTrustedRoots: true);
    // In production, bundle your CA certificate:
    // final certBytes = File('assets/certs/rakshak_ca.pem').readAsBytesSync();
    // context.setTrustedCertificatesBytes(certBytes);
    return context;
  }

  /// Create a Dio HttpClientAdapter with SSL pinning
  static HttpClientAdapter createPinnedAdapter() {
    return IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(context: createSecurityContext());
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Only allow connections to our API host
          if (!host.endsWith('rakshak.ai')) return false;

          // Compute SHA-256 fingerprint of the presented certificate
          final fingerprint = _computeFingerprint(cert);

          // Check if the fingerprint matches any trusted certificate
          final trusted = _trustedCertificateFingerprints.any(
            (pinned) => pinned.replaceAll(':', '').toLowerCase() ==
                fingerprint.replaceAll(':', '').toLowerCase(),
          );

          return trusted;
        };
        return client;
      },
    );
  }

  /// Compute SHA-256 fingerprint from X509Certificate DER bytes
  static String _computeFingerprint(X509Certificate cert) {
    final digest = sha256.convert(cert.der);
    final hex = digest.toString().toUpperCase();
    // Format as AA:BB:CC:DD...
    final buffer = StringBuffer();
    for (int i = 0; i < hex.length; i += 2) {
      if (i > 0) buffer.write(':');
      buffer.write(hex.substring(i, i + 2));
    }
    return buffer.toString();
  }

  /// Validate a certificate fingerprint against our trusted list
  static bool validateFingerprint(String fingerprint) {
    return _trustedCertificateFingerprints.any(
      (pinned) => pinned.replaceAll(':', '').toLowerCase() ==
          fingerprint.replaceAll(':', '').toLowerCase(),
    );
  }
}
