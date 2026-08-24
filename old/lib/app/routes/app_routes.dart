class AppRoutes {
  static const home = '/';
  static const qrScanner = '/scanner';
  static const guestPattern = '/guest/:token';
  static const recordingPattern = '/guest/:token/record';
  static const tables = '/tables';

  static String guest(String token) => '/guest/$token';
  static String recording(String token) => '/guest/$token/record';
}
