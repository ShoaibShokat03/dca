import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/question.dart';
import '../../models/quiz.dart';
import '../../models/quiz_result.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'quiz_result_screen.dart';

class QuizAttemptScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizAttemptScreen({super.key, required this.quiz});

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  bool _loading = true;
  String? _error;
  List<Question> _questions = [];
  Map<int, StudentResponse> _attempted = {}; // question_id → response
  int _qn = 1;
  bool _skippedMode = false;
  int _skippedIndex = 0;
  List<Question> _skippedQuestions = [];

  // Selected answer for current question
  int? _selectedAnswerId;
  String? _selectedTfValue;
  final _textCtrl = TextEditingController();

  // Submit state
  bool _submitting = false;
  bool _showFeedback = false;
  String? _feedbackText;
  bool _isCorrectFeedback = false;

  // Timer
  Timer? _timer;
  Timer? _logTimer;
  int _remainingSeconds = 0;
  int _spentSinceLastLog = 0;
  int _clockOffsetMs = 0;
  DateTime? _quizEndAt;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logTimer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() { _loading = true; _error = null; });
    try {
      // 1. Start the quiz (creates time log if needed) — get time info
      final start = await ApiService.post(ApiConfig.quizStart(widget.quiz.id));
      if (start.success && start.data is Map<String, dynamic>) {
        final time = start.data['time'];
        if (time is Map<String, dynamic>) {
          final t = QuizTimeInfo.fromJson(time);
          _remainingSeconds = t.remainingSeconds;
          if (t.serverNowUtc != null) {
            final serverNow = DateTime.parse(t.serverNowUtc!).millisecondsSinceEpoch;
            _clockOffsetMs = serverNow - DateTime.now().millisecondsSinceEpoch;
          }
          _quizEndAt = DateTime.now().add(Duration(seconds: _remainingSeconds));
        }
      } else if (!start.success) {
        if (start.statusCode == 403) {
          // Quiz already over or assigned issue — show result
          if (mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuizResultScreen(quizId: widget.quiz.id)));
          }
          return;
        }
      }

      // 2. Load questions and attempted answers
      final res = await ApiService.get(ApiConfig.quizQuestions(widget.quiz.id));
      if (res.success && res.data is Map<String, dynamic>) {
        final qList = (res.data['questions'] as List?) ?? [];
        final aList = (res.data['attempted'] as List?) ?? [];
        _questions = qList.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList();
        _attempted = {
          for (var a in aList.map((e) => StudentResponse.fromJson(e as Map<String, dynamic>))) a.questionId: a
        };
        _showCurrent();
      } else {
        _error = res.message;
      }

      _startTimers();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _startTimers() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() { _remainingSeconds = (_remainingSeconds - 1).clamp(0, 1 << 30); });
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _logTimer?.cancel();
        _gotoResult();
      }
      _spentSinceLastLog++;
    });
    _logTimer?.cancel();
    _logTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_spentSinceLastLog > 0) {
        try {
          await ApiService.post(ApiConfig.quizTimeLog(widget.quiz.id), body: {'time': _spentSinceLastLog});
          _spentSinceLastLog = 0;
        } catch (_) {/* ignore */}
      }
    });
  }

  Question? get _currentQuestion {
    try { return _questions.firstWhere((q) => q.qnumber == _qn); } catch (_) { return null; }
  }

  void _showCurrent() {
    setState(() {
      _selectedAnswerId = null;
      _selectedTfValue = 'true';
      _textCtrl.text = '';
      _showFeedback = false;
      _feedbackText = null;
    });
    final q = _currentQuestion;
    if (q == null) return;
    final attempt = _attempted[q.id];
    if (attempt != null) {
      // Show feedback for already-attempted question
      _selectedAnswerId = attempt.answerId;
      _selectedTfValue = attempt.studentAnswer;
      _textCtrl.text = attempt.studentAnswer ?? '';
      _showAnswerFeedback(q, attempt);
    }
  }

  void _showAnswerFeedback(Question q, StudentResponse a) {
    if (q.type == 'mcq') {
      Answer? selected;
      try { selected = q.answers.firstWhere((ans) => ans.id == a.answerId); } catch (_) {}
      final correct = selected?.isCorrect == 1;
      setState(() {
        _showFeedback = true;
        _isCorrectFeedback = correct;
        _feedbackText = correct ? 'Correct!' : 'Incorrect!';
      });
    } else if (q.type == 'truefalse') {
      // We can't fully verify; just show "submitted"
      setState(() { _showFeedback = true; _isCorrectFeedback = true; _feedbackText = 'Submitted'; });
    } else if (q.type == 'text') {
      setState(() { _showFeedback = true; _isCorrectFeedback = true; _feedbackText = 'Submitted'; });
    }
  }

  List<Question> _getUnattempted() {
    return _questions.where((q) => !_attempted.containsKey(q.id)).toList();
  }

  void _enterSkippedMode() {
    final un = _getUnattempted();
    if (un.isEmpty) { _gotoResult(); return; }
    setState(() {
      _skippedMode = true;
      _skippedIndex = 0;
      _skippedQuestions = un;
      _qn = un[0].qnumber;
    });
    _showCurrent();
  }

  void _skip() {
    if (_skippedMode) {
      _skippedQuestions = _getUnattempted();
      if (_skippedQuestions.isEmpty) { _gotoResult(); return; }
      var pos = _skippedQuestions.indexWhere((q) => q.qnumber == _qn);
      if (pos < 0 || pos >= _skippedQuestions.length - 1) {
        _skippedIndex = 0;
      } else {
        _skippedIndex = pos + 1;
      }
      setState(() => _qn = _skippedQuestions[_skippedIndex].qnumber);
      _showCurrent();
    } else {
      if (_qn < _questions.length) {
        setState(() => _qn++);
        _showCurrent();
      } else {
        _enterSkippedMode();
      }
    }
  }

  void _next() {
    if (_skippedMode) {
      _skippedQuestions = _getUnattempted();
      if (_skippedQuestions.isEmpty) { _gotoResult(); return; }
      if (_skippedIndex >= _skippedQuestions.length) _skippedIndex = 0;
      setState(() => _qn = _skippedQuestions[_skippedIndex].qnumber);
      _showCurrent();
    } else if (_qn < _questions.length) {
      setState(() => _qn++);
      _showCurrent();
    } else {
      _enterSkippedMode();
    }
  }

  void _back() {
    if (_skippedMode) {
      _skippedQuestions = _getUnattempted();
      if (_skippedQuestions.isEmpty) { _gotoResult(); return; }
      _skippedIndex--;
      if (_skippedIndex < 0) _skippedIndex = _skippedQuestions.length - 1;
      setState(() => _qn = _skippedQuestions[_skippedIndex].qnumber);
    } else if (_qn > 1) {
      setState(() => _qn--);
    }
    _showCurrent();
  }

  void _gotoResult() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuizResultScreen(quizId: widget.quiz.id)));
  }

  Future<void> _submit() async {
    final q = _currentQuestion;
    if (q == null) return;
    String? answerValue;
    if (q.type == 'mcq') {
      if (_selectedAnswerId == null) {
        showSnack(context, 'Please select an option', error: true);
        return;
      }
      answerValue = '$_selectedAnswerId';
    } else if (q.type == 'truefalse') {
      answerValue = _selectedTfValue ?? 'true';
    } else if (q.type == 'text') {
      if (_textCtrl.text.trim().isEmpty) {
        showSnack(context, 'Please enter your answer', error: true);
        return;
      }
      answerValue = _textCtrl.text.trim();
    }

    setState(() => _submitting = true);
    try {
      final res = await ApiService.post(
        ApiConfig.quizSubmitAnswer(widget.quiz.id),
        body: {'qnumber': _qn, 'answer': answerValue, 'session': widget.quiz.sessionId ?? 0},
      );
      if (res.success && res.data is Map<String, dynamic>) {
        final attempted = StudentResponse.fromJson(res.data as Map<String, dynamic>);
        _attempted[q.id] = attempted;
        _showAnswerFeedback(q, attempted);
        if (_attempted.length == _questions.length) {
          // All done
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) _gotoResult();
        }
      } else {
        showSnack(context, res.message, error: true);
      }
    } catch (e) {
      showSnack(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _submitting = false);
  }

  String _formatTime(int s) {
    if (s <= 0) return 'Time Up';
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress is saved. You can resume from the quizzes list.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Stay')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Exit')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _bootstrap)
                  : _questions.isEmpty
                      ? const Center(child: Text('No questions found', style: TextStyle(color: Colors.white)))
                      : _buildAttempt(),
        ),
      ),
    );
  }

  Widget _buildAttempt() {
    final q = _currentQuestion;
    if (q == null) return const Center(child: Text('Loading...', style: TextStyle(color: Colors.white)));
    final isAttempted = _attempted.containsKey(q.id);
    final unattemptedCount = _getUnattempted().length;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF0F3460),
          child: Row(
            children: [
              IconButton(
                onPressed: () async { if (await _confirmExit()) Navigator.of(context).pop(); },
                icon: const Icon(Icons.close, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _skippedMode ? 'Q$_qn · $unattemptedCount left' : '$_qn / ${_questions.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text('Attempted ${_attempted.length}/${_questions.length}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(10)),
                child: Text(_formatTime(_remainingSeconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(q.questionText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.5)),
                const SizedBox(height: 28),
                if (q.type == 'mcq') _buildMcq(q, isAttempted),
                if (q.type == 'truefalse') _buildTf(isAttempted),
                if (q.type == 'text') _buildText(isAttempted),
                if (_showFeedback && _feedbackText != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_isCorrectFeedback ? Colors.green : Colors.red).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isCorrectFeedback ? Icons.check_circle : Icons.cancel, color: _isCorrectFeedback ? Colors.greenAccent : Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(_feedbackText!, style: TextStyle(color: _isCorrectFeedback ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Footer buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          color: const Color(0xFF0F3460),
          child: Row(
            children: [
              if (_qn > 1 || _skippedMode)
                _footerBtn(Icons.chevron_left, 'Prev', AppTheme.info, const Color(0xFF0F3460), _back),
              const Spacer(),
              if (!isAttempted) _footerBtn(Icons.skip_next, 'Skip', AppTheme.accent, Colors.white, _skip),
              const SizedBox(width: 8),
              if (isAttempted)
                _footerBtn(Icons.chevron_right, 'Next', AppTheme.success, Colors.white, _next)
              else
                _footerBtn(Icons.check, 'Submit', AppTheme.success, Colors.white, _submitting ? null : _submit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footerBtn(IconData icon, String label, Color bg, Color fg, VoidCallback? onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildMcq(Question q, bool disabled) {
    return Column(
      children: q.answers.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        final letter = String.fromCharCode(65 + i);
        final selected = _selectedAnswerId == a.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: disabled ? null : () => setState(() => _selectedAnswerId = a.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppTheme.info.withOpacity(0.12) : Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: selected ? AppTheme.info : Colors.white.withOpacity(0.15),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.info : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(letter, style: TextStyle(color: selected ? const Color(0xFF0F3460) : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(a.answerText, style: TextStyle(color: Colors.white.withOpacity(disabled ? 0.7 : 1), fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTf(bool disabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ['true', 'false'].map((v) {
        final selected = _selectedTfValue == v;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: disabled ? null : () => setState(() => _selectedTfValue = v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppTheme.info.withOpacity(0.12) : Colors.white.withOpacity(0.08),
                border: Border.all(color: selected ? AppTheme.info : Colors.white.withOpacity(0.15), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(v == 'true' ? 'True' : 'False', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildText(bool disabled) {
    return TextField(
      controller: _textCtrl,
      enabled: !disabled,
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Enter your answer...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.info, width: 2)),
      ),
    );
  }
}
