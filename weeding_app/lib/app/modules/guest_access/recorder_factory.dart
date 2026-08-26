import 'package:flutter/material.dart';

/// Stub factory for non-web platforms.
/// The real implementation lives in recorder_factory_web.dart and is only
/// loaded via conditional import when targeting web.
/// These functions exist here so the analyzer finds them on non-web builds,
/// but they are never called because kIsWeb guards the call sites.

Widget buildWebAudioRecorderPage({int minDurationSeconds = 30}) {
  return const Scaffold(
    body: Center(
      child: Text('Enregistrement web non disponible sur cette plateforme.'),
    ),
  );
}

Widget buildWebVideoRecorderPage({int minDurationSeconds = 30}) {
  return const Scaffold(
    body: Center(
      child: Text('Enregistrement web non disponible sur cette plateforme.'),
    ),
  );
}
