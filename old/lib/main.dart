import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'app/core/services/deep_link_service.dart';
import 'app/core/services/invitation_export_service.dart';
import 'app/core/services/supabase_service.dart';
import 'app/data/repositories/wedding_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync(() => SupabaseService().init(), permanent: true);
  Get.put(InvitationExportService(), permanent: true);
  await Get.putAsync(() => WeddingRepository().init(), permanent: true);
  await Get.putAsync(() => DeepLinkService().init(), permanent: true);

  runApp(const WeddingInvitationApp());
}
