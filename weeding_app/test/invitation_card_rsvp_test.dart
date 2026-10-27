import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/core/utils/invitation_card_generator.dart';

void main() {
  testWidgets(
    'La carte d\'invitation affiche la ligne RSVP '
    '« Confirmation de présence … 5 novembre 2026 »',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
            child: InvitationCardWidget(
              guestName: 'Ana K.',
              tableName: 'Table 1',
              seatNumber: '3',
            ),
            ),
          ),
        ),
      );

      expect(
        find.text(
          'RSVP — Confirmation de présence souhaitée '
          'au plus tard le 5 novembre 2026.',
        ),
        findsOneWidget,
      );
      // Contrôle : le reste de la carte est bien rendu.
      expect(find.text('Ana K.'), findsOneWidget);
      expect(find.text('Table 1'), findsOneWidget);
    },
  );
}
