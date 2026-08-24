import 'package:get/get.dart';

import '../../core/services/invitation_export_service.dart';
import '../../data/models/invitation_models.dart';
import '../../data/repositories/wedding_repository.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  final WeddingRepository _repository = Get.find<WeddingRepository>();
  final InvitationExportService _exportService =
      Get.find<InvitationExportService>();

  final tables = <WeddingTable>[].obs;
  final guests = <WeddingGuest>[].obs;
  final invitations = <GuestInvitation>[].obs;
  final isBusy = false.obs;

  WeddingEvent get event => _repository.event;
  bool get isRemoteConfigured => _repository.isRemoteConfigured;
  bool get hasAdminSession => _repository.hasAdminSession;
  bool get isAdminDemoMode => _repository.isAdminDemoMode;

  int get freeSeats => tables.fold<int>(
    0,
    (sum, table) => sum + table.capacity - table.occupiedSeats,
  );

  int get unlockedCards => invitations.where((item) => item.isUnlocked).length;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  void refreshData() {
    tables.assignAll(_repository.tables);
    guests.assignAll(_repository.guests);
    invitations.assignAll(_repository.invitations);
  }

  List<ChairModel> availableChairsForGuest(WeddingGuest guest) {
    return _repository.availableChairs(includeGuestId: guest.id);
  }

  String seatLabelFromChairId(String chairId) {
    final table = _repository.tableForChair(chairId);
    final chair = table?.chairs.firstWhereOrNull((item) => item.id == chairId);
    if (table == null || chair == null) {
      return 'Chaise inconnue';
    }
    return '${table.label} • chaise ${chair.number}';
  }

  GuestInvitation? invitationForGuest(String guestId) {
    return _repository.invitationForGuest(guestId);
  }

  Future<void> createTable({
    required String label,
    required int capacity,
  }) async {
    await _runBusy(() async {
      await _repository.createTable(label: label, capacity: capacity);
      refreshData();
      Get.snackbar('Table ajoutee', '$label avec $capacity chaises');
    });
  }

  Future<void> createGuest({
    required String fullName,
    required String phone,
    required String email,
  }) async {
    await _runBusy(() async {
      await _repository.createGuest(
        fullName: fullName,
        phone: phone,
        email: email,
      );
      refreshData();
      Get.snackbar('Invite ajoute', fullName);
    });
  }

  Future<void> assignGuest({
    required WeddingGuest guest,
    required String chairId,
  }) async {
    await _runBusy(() async {
      final invitation = await _repository.assignGuestToChair(
        guestId: guest.id,
        chairId: chairId,
      );
      await _generateAssets(invitation);
      refreshData();
      Get.snackbar(
        'Invitation generee',
        '${guest.fullName} a maintenant une carte avec QR code.',
      );
    });
  }

  Future<void> regenerateAssets(String invitationId) async {
    await _runBusy(() async {
      final invitation = invitations.firstWhere(
        (item) => item.id == invitationId,
      );
      final assets = await _generateAssets(invitation);
      await _exportService.shareAssets(assets);
      refreshData();
      Get.snackbar(
        'Export termine',
        'Les versions PNG et PDF sont pretes a etre partagees.',
      );
    });
  }

  void openGuestAccess(String token) {
    Get.toNamed(AppRoutes.guest(token));
  }

  Future<InvitationAssetBundle> _generateAssets(
    GuestInvitation invitation,
  ) async {
    final assets = await _exportService.generateAssets(
      event: event,
      invitation: invitation,
    );
    await _repository.attachGeneratedAssets(
      invitationId: invitation.id,
      pngStoragePath: 'invitation-cards/png/${assets.pngFileName}',
      pdfStoragePath: 'invitation-cards/pdf/${assets.pdfFileName}',
    );
    return assets;
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (isBusy.value) {
      return;
    }

    isBusy.value = true;
    try {
      await action();
    } catch (error) {
      Get.snackbar('Operation impossible', '$error');
    } finally {
      isBusy.value = false;
    }
  }
}
