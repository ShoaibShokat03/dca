import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/quiz.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'quiz_attempt_screen.dart';
import 'quiz_result_screen.dart';
import 'reattempt_dialog.dart';
import 'widgets/quiz_card.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  bool _loading = true;
  String? _error;
  List<Quiz> _quizzes = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.quizzes);
      if (res.success && res.data is List) {
        _quizzes = (res.data as List).map((q) => Quiz.fromJson(q as Map<String, dynamic>)).toList();
      } else {
        _error = res.message;
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  void _openReattempt(Quiz q) {
    showDialog(context: context, builder: (_) => ReattemptDialog(quiz: q));
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
                title: 'My Quizzes',
                subtitle: '${_quizzes.length} quizzes available',
                icon: Icons.help_outline,
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _quizzes.isEmpty
                          ? const EmptyView(icon: Icons.help_outline, title: 'No quizzes', message: 'No quizzes assigned yet.')
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppTheme.primary,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                itemCount: _quizzes.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) => QuizCard(
                                  quiz: _quizzes[i],
                                  onAttempt: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizAttemptScreen(quiz: _quizzes[i]))),
                                  onResult: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizResultScreen(quizId: _quizzes[i].id))),
                                  onReattempt: () => _openReattempt(_quizzes[i]),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
