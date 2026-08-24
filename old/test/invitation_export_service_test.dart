import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/app/core/services/invitation_export_service.dart';
import 'package:mobile_app/app/data/models/invitation_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateAssets produit un PNG et un PDF exploitables', () async {
    const event = WeddingEvent(
      id: 'event-test',
      title: 'Mariage Test',
      brideName: 'Aimee',
      groomName: 'Entienne',
      location: 'Abidjan',
      eventDateLabel: 'Decembre 2026',
    );
    const invitation = GuestInvitation(
      id: 'inv-1',
      guestId: 'guest-1',
      guestName: 'Stephanie K.',
      guestStatus: GuestStatus.cardUnlocked,
      tableId: 'table-1',
      tableLabel: 'Famille',
      chairId: 'chair-1',
      chairNumber: 3,
      token: 'stephaniek001',
      invitationCode: 'STEPH001',
      webUrl: 'https://example.com/#/guest/stephaniek001',
      deepLink: 'mariageentienne://guest/stephaniek001',
      isUnlocked: true,
      pngStoragePath: null,
      pdfStoragePath: null,
      signedPngUrl: null,
      signedPdfUrl: null,
      mediaSubmissions: [],
    );

    final service = InvitationExportService();
    final assets = await service.generateAssets(
      event: event,
      invitation: invitation,
    );

    expect(assets.pngBytes, isNotEmpty);
    expect(assets.pdfBytes, isNotEmpty);
    expect(assets.pngFileName, 'invitation-steph001.png');
    expect(assets.pdfFileName, 'invitation-steph001.pdf');
  });
}
