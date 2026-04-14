import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/video.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/lecture_card.dart';
import '../video_player_screen.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  bool _loading = true;
  String? _error;
  List<VideoItem> _videos = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.lectures);
      if (res.success && res.data is List) {
        _videos = (res.data as List).map((v) => VideoItem.fromJson(v as Map<String, dynamic>)).toList();
      } else {
        _error = res.message;
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  void _openVideo(VideoItem v) {
    if (v.filePath == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: v.filePath!, title: v.title)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: PageHeader(
                title: 'My Lectures',
                subtitle: '${_videos.length} lectures available',
                icon: Icons.play_circle,
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _videos.isEmpty
                          ? const EmptyView(icon: Icons.movie_outlined, title: 'No lectures', message: 'No lectures available yet.')
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppTheme.primary,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                itemCount: _videos.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, i) => LectureCard(video: _videos[i], onPlay: () => _openVideo(_videos[i])),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
