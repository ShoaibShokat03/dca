import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_theme.dart';

/// HLS / MP4 video player screen.
/// `video_player` natively supports HLS on Android (ExoPlayer) and iOS (AVPlayer).
class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  const VideoPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoCtrl!.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.accent,
          handleColor: AppTheme.accent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white24,
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (ctx, err) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(err, style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load video: $e');
    }
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
      ),
      body: Center(
        child: _error != null
            ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.white)))
            : _chewieCtrl != null && _videoCtrl != null && _videoCtrl!.value.isInitialized
                ? AspectRatio(aspectRatio: _videoCtrl!.value.aspectRatio, child: Chewie(controller: _chewieCtrl!))
                : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
