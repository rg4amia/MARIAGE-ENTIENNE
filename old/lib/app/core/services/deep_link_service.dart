import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../../routes/app_routes.dart';

class DeepLinkService extends GetxService {
  StreamSubscription<Uri>? _subscription;

  Future<DeepLinkService> init() async {
    if (kIsWeb) {
      return this;
    }

    final appLinks = AppLinks();

    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
    } catch (_) {
      // Ignore malformed links and let the user continue manually.
    }

    _subscription = appLinks.uriLinkStream.listen(_handleUri);
    return this;
  }

  void _handleUri(Uri uri) {
    final token = AppConfig.extractToken(uri);
    if (token == null || token.isEmpty) {
      return;
    }

    final route = AppRoutes.guest(token);
    if (Get.currentRoute != route) {
      Get.toNamed(route);
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
