import 'package:flutter/material.dart';
import 'web_audio_recorder.dart';
import 'web_video_recorder.dart';

/// Returns the web audio recorder page. Only loaded on web via conditional import.
Widget buildWebAudioRecorderPage({int minDurationSeconds = 30}) {
  return WebAudioRecorderPage(minDurationSeconds: minDurationSeconds);
}

/// Returns the web video recorder page. Only loaded on web via conditional import.
Widget buildWebVideoRecorderPage({int minDurationSeconds = 30}) {
  return WebVideoRecorderPage(minDurationSeconds: minDurationSeconds);
}
