class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://sckvfrsjmbwkuqdfsgki.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNja3ZmcnNqbWJ3a3VxZGZzZ2tpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0Mjk3NjksImV4cCI6MjA5MTAwNTc2OX0.COR213RZwFlG1UZ2wtCJgSTaMvsqGQ7cbOvB9Xs5woY',
  );

  static const publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: '',
  );

  static const appScheme = 'mariageentienne';

  static bool get hasSupabaseCredentials => supabaseAnonKey.isNotEmpty;

  static Uri buildWebGuestUri(String token) {
    return Uri.parse('${_resolvedPublicBaseUrl()}/#/guest/$token');
  }

  static Uri buildDeepLink(String token) {
    return Uri.parse('$appScheme://guest/$token');
  }

  static String? extractToken(Uri uri) {
    if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'guest') {
      return uri.pathSegments[1];
    }

    if (uri.fragment.isNotEmpty) {
      final fragmentUri = Uri.parse(
        uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}',
      );
      if (fragmentUri.pathSegments.length >= 2 &&
          fragmentUri.pathSegments.first == 'guest') {
        return fragmentUri.pathSegments[1];
      }
    }

    if (uri.host == 'guest' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    return uri.queryParameters['token'];
  }

  static String _resolvedPublicBaseUrl() {
    if (publicBaseUrl.isNotEmpty) {
      return publicBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    return Uri.base.origin;
  }
}
