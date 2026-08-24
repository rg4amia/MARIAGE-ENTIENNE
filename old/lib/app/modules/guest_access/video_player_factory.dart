import 'package:video_player/video_player.dart';

import 'video_player_factory_stub.dart'
    if (dart.library.io) 'video_player_factory_io.dart'
    as impl;

VideoPlayerController createVideoController(String path) {
  return impl.createVideoController(path);
}
