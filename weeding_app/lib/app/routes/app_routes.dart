class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const plans = '/plans';
  static const home = '/home';
  static const tables = '/tables';
  static const tableDetail = '/tables/:id';
  static const guests = '/guests';
  static const guestDetail = '/guests/:id';
  static const invitations = '/invitations';
  static const qrCode = '/invitations/:guestId/qr';
  static const entranceQr = '/invitations/entrance';
  static const settings = '/settings';
  static const venues = '/venues';
  static const weddingTheme = '/settings/wedding-theme';
  static const admin = '/admin';

  /// Écrans accessibles sans session : la page de garde et ses deux entrées.
  static const publicRoutes = <String>{splash, welcome, login, register};
}
