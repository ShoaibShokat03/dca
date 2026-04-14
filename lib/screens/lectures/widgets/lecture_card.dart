import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/video.dart';
import '../../../widgets/common_widgets.dart';

class LectureCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onPlay;

  const LectureCard({super.key, required this.video, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final uuid = ApiConfig.extractUuid(video.filePath);
    final poster = uuid != null ? ApiConfig.posterUrl(uuid) : null;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onPlay,
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 110, height: 70,
            decoration: BoxDecoration(color: const Color(0xFFE8EEF4), borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (poster != null)
                  Image.network(poster, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie, color: AppTheme.primary, size: 28)))
                else
                  const Center(child: Icon(Icons.movie, color: AppTheme.primary, size: 28)),
                Container(color: Colors.black.withOpacity(0.15), alignment: Alignment.center, child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (video.sessionName != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.event, size: 11, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(video.sessionName!, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
                  ]),
                ],
                if (video.quizTitle != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.help_outline, size: 11, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(video.quizTitle!, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
