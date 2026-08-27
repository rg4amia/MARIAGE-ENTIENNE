import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weeding_app/app/modules/invitations/entrance_qr_page.dart';

void main() {
  test('explains a missing event profile without blaming connectivity', () {
    const error = PostgrestException(
      message: 'No wedding event is attached to this administrator',
      code: 'P0001',
    );

    expect(
      entranceQrErrorMessage(error),
      'Votre compte administrateur n’est associé à aucun mariage.',
    );
  });

  test('asks a non-admin user to reconnect', () {
    const error = PostgrestException(
      message: 'Administrator access required',
      code: 'P0001',
    );

    expect(
      entranceQrErrorMessage(error),
      'Accès administrateur requis. Reconnectez-vous.',
    );
  });

  test('keeps the Supabase diagnostic for unexpected database errors', () {
    const error = PostgrestException(
      message: 'Unexpected database error',
      code: 'XX000',
    );

    expect(
      entranceQrErrorMessage(error),
      'Erreur Supabase (XX000) : Unexpected database error',
    );
  });
}
