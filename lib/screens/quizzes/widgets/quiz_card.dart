import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/quiz.dart';
import '../../../widgets/common_widgets.dart';

class QuizCard extends StatefulWidget {
  final Quiz quiz;
  final VoidCallback? onAttempt;
  final VoidCallback? onResult;
  final VoidCallback? onReattempt;

  const QuizCard({super.key, required this.quiz, this.onAttempt, this.onResult, this.onReattempt});

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  Timer? _timer;
  String _remaining = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final end = widget.quiz.endDateTime;
    if (end == null) return;
    final secs = end.difference(DateTime.now()).inSeconds;
    if (secs <= 0) {
      _timer?.cancel();
      if (mounted) setState(() => _remaining = 'Time Up');
      return;
    }
    final d = secs ~/ 86400;
    final h = (secs % 86400) ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    String text = '';
    if (d > 0) text += '${d}d ';
    if (h > 0) text += '${h}h ';
    if (m > 0) text += '${m}m ';
    text += '${s}s';
    if (mounted) setState(() => _remaining = text);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quiz;
    final active = q.isActive;
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: active ? AppTheme.borderLight : AppTheme.borderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(q.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              ),
              const SizedBox(width: 8),
              active
                  ? const StatusBadge.success(text: 'Active', icon: Icons.circle)
                  : const StatusBadge.danger(text: 'Expired', icon: Icons.circle),
            ],
          ),
          if (q.sessionName != null) ...[
            const SizedBox(height: 4),
            Text(q.sessionName!, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
          if (q.description != null && q.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(q.description!, style: const TextStyle(fontSize: 12.5, color: AppTheme.textBody, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10)),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _meta(Icons.format_list_numbered, '${q.questionCount} Questions'),
                if (q.durationMinutes != null) _meta(Icons.timer, '${q.durationMinutes} min'),
                _meta(Icons.hourglass_bottom, _remaining.isEmpty ? '...' : _remaining, color: active ? AppTheme.primaryLight : AppTheme.danger, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (active && !q.isAttempted)
                _btn(Icons.play_arrow, 'Attempt Quiz', AppTheme.primary, Colors.white, widget.onAttempt),
              if (q.isAttempted)
                _btn(Icons.bar_chart, 'Results', AppTheme.success, Colors.white, widget.onResult),
              if (active && q.isAttempted)
                _btn(Icons.visibility, 'View Quiz', const Color(0xFFE8EEF4), AppTheme.primary, widget.onAttempt),
              if (q.isAttempted)
                _btn(Icons.refresh, 'Re-Attempt', AppTheme.warning, const Color(0xFF212529), widget.onReattempt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.primary),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12, color: color ?? AppTheme.textBody, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _btn(IconData icon, String label, Color bg, Color fg, VoidCallback? onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
