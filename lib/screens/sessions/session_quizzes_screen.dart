import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/quiz.dart';
import '../../models/session.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../quizzes/quiz_attempt_screen.dart';
import '../quizzes/quiz_result_screen.dart';
import '../quizzes/widgets/quiz_card.dart';

class SessionQuizzesScreen extends StatefulWidget {
  final SessionItem session;
  const SessionQuizzesScreen({super.key, required this.session});

  @override
  State<SessionQuizzesScreen> createState() => _SessionQuizzesScreenState();
}

class _SessionQuizzesScreenState extends State<SessionQuizzesScreen> {
  bool _loading = true;
  String? _error;
  List<Quiz> _quizzes = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.sessionQuizzes(widget.session.id));
      if (res.success && res.data is Map<String, dynamic>) {
        final list = (res.data['quizzes'] as List?) ?? [];
        _quizzes = list.map((q) => Quiz.fromJson({...q as Map<String, dynamic>, 'session_id': widget.session.id, 'session_name': widget.session.name})).toList();
      } else {
        _error = res.message;
      }
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
                title: widget.session.name,
                subtitle: '${_quizzes.length} quizzes in this session',
                icon: Icons.help_outline,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _quizzes.isEmpty
                          ? const EmptyView(icon: Icons.help_outline, title: 'No quizzes', message: 'This session has no quizzes yet.')
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
