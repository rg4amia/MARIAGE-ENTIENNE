import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createVideoController(String path) {
  if (path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('blob:') ||
      path.startsWith('data:')) {
    return VideoPlayerController.networkUrl(Uri.parse(path));
  }

  return VideoPlayerController.file(File(path));
}
