import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/quiz_result.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class QuizResultScreen extends StatefulWidget {
  final int quizId;
  const QuizResultScreen({super.key, required this.quizId});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _loading = true;
  String? _error;
  QuizResult? _result;
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.quizResult(widget.quizId));
      if (res.success && res.data is Map<String, dynamic>) {
        _result = QuizResult.fromJson(res.data as Map<String, dynamic>);
      } else { _error = res.message; }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
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
                title: _result?.quizTitle ?? 'Quiz Result',
                icon: Icons.assessment,
                onBack: () => Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == '/home'),
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _result == null
                          ? const EmptyView(icon: Icons.error_outline, title: 'No result')
                          : _build(_result!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build(QuizResult r) {
    final filtered = r.questions.where((q) {
      if (_filter == 'all') return true;
      return q.status == _filter;
    }).toList();
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score + stats
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(
                    width: 110, height: 110,
                    child: Stack(alignment: Alignment.center, children: [
                      CustomPaint(size: const Size(110, 110), painter: _CirclePainter(r.percentage / 100)),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${r.percentage}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        const Text('Score', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                      ]),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.4,
                      children: [
                        _statBox(Icons.list, AppTheme.primary, '${r.totalQuestions}', 'Total'),
                        _statBox(Icons.check, AppTheme.success, '${r.totalCorrect}', 'Correct'),
                        _statBox(Icons.close, AppTheme.danger, '${r.totalIncorrect}', 'Wrong'),
                        _statBox(Icons.skip_next, AppTheme.warning, '${r.unattempted}', 'Skipped'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All', 'all'),
                  _chip('Correct', 'correct'),
                  _chip('Wrong', 'incorrect'),
                  _chip('Skipped', 'unattempted'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Questions
            ...filtered.map((q) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFE8EEF4), borderRadius: BorderRadius.circular(8)),
                              child: Text('Q${q.qn}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                            ),
                            const Spacer(),
                            _statusBadge(q.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(q.questionText, style: const TextStyle(fontSize: 13.5, color: AppTheme.textBody, height: 1.4)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _ansBox('Your Answer', q.studentAnswer ?? 'Not Attempted', _statusColor(q.status))),
                            const SizedBox(width: 8),
                            Expanded(child: _ansBox('Correct Answer', q.correctAnswer, const Color(0xFFD4EDDA))),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    if (s == 'correct') return const Color(0xFFD4EDDA);
    if (s == 'incorrect') return const Color(0xFFF8D7DA);
    return const Color(0xFFFFF3CD);
  }

  Widget _statusBadge(String s) {
    if (s == 'correct') return const StatusBadge.success(text: 'Correct', icon: Icons.check_circle);
    if (s == 'incorrect') return const StatusBadge.danger(text: 'Wrong', icon: Icons.cancel);
    return const StatusBadge.warning(text: 'Skipped', icon: Icons.remove_circle_outline);
  }

  Widget _statBox(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)), child: Icon(icon, color: Colors.white, size: 14)),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textBody, fontWeight: FontWeight.w500, fontSize: 12),
        side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
      ),
    );
  }

  Widget _ansBox(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textBody)),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress; // 0..1
  _CirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final bg = Paint()..color = const Color(0xFFE9ECEF)..style = PaintingStyle.stroke..strokeWidth = 10;
    final fg = Paint()..color = AppTheme.success..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    final sweep = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) => oldDelegate.progress != progress;
}
