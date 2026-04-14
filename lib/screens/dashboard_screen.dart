import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/news.dart';
import '../models/session.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'live_stream_screen.dart';
import 'news_screen.dart';
import 'sessions/session_quizzes_screen.dart';
import 'sessions/sessions_screen.dart';
import 'lectures/lectures_screen.dart';
import 'quizzes/quizzes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  int _sessionCount = 0;
  int _lectureCount = 0;
  int _quizCount = 0;
  int _attemptedCount = 0;
  List<NewsItem> _news = [];
  List<dynamic> _recentAssignments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.dashboard);
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        _sessionCount = (d['session_count'] as num?)?.toInt() ?? 0;
        _lectureCount = (d['lecture_count'] as num?)?.toInt() ?? 0;
        _quizCount = (d['quiz_count'] as num?)?.toInt() ?? 0;
        _attemptedCount = (d['attempted_quiz_count'] as num?)?.toInt() ?? 0;
        final newsList = (d['news'] as List?) ?? [];
        _news = newsList.map((n) => NewsItem.fromJson(n as Map<String, dynamic>)).toList();
        _recentAssignments = (d['recent_assignments'] as List?) ?? [];
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.headerGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.displayName ?? 'Student',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_loading) const SizedBox(height: 200, child: LoadingView()),
                if (_error != null) ErrorView(message: _error!, onRetry: _load),

                if (!_loading && _error == null) ...[
                  // Stats grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: [
                      _StatTile(
                        icon: Icons.calendar_today,
                        color: AppTheme.primary,
                        label: 'Sessions',
                        value: _sessionCount,
                        onTap: () => _navTo(const SessionsScreen()),
                      ),
                      _StatTile(
                        icon: Icons.play_circle,
                        color: AppTheme.primaryLight,
                        label: 'Lectures',
                        value: _lectureCount,
                        onTap: () => _navTo(const LecturesScreen()),
                      ),
                      _StatTile(
                        icon: Icons.help_outline,
                        color: AppTheme.accent,
                        label: 'Quizzes',
                        value: _quizCount,
                        onTap: () => _navTo(const QuizzesScreen()),
                      ),
                      _StatTile(
                        icon: Icons.check_circle,
                        color: AppTheme.success,
                        label: 'Attempted',
                        value: _attemptedCount,
                        onTap: () => _navTo(const QuizzesScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions
                  Row(
                    children: [
                      _QuickAction(icon: Icons.live_tv, label: 'Live', onTap: () => _navTo(const LiveStreamScreen())),
                      _QuickAction(icon: Icons.newspaper, label: 'News', onTap: () => _navTo(const NewsScreen())),
                      _QuickAction(icon: Icons.quiz, label: 'Take Quiz', onTap: () => _navTo(const QuizzesScreen())),
                      _QuickAction(icon: Icons.assessment, label: 'Results', onTap: () => _navTo(const QuizzesScreen())),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // News card
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            children: [
                              const Icon(Icons.campaign, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('News & Updates', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                              ),
                              if (_news.isNotEmpty)
                                TextButton(onPressed: () => _navTo(const NewsScreen()), child: const Text('See all')),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (_news.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No news yet.', style: TextStyle(color: AppTheme.textMuted))),
                          )
                        else
                          ..._news.take(3).map((n) => Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                    if (n.description != null && n.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(n.description!, style: const TextStyle(fontSize: 13, color: AppTheme.textBody), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Recent assignments
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            children: [
                              Icon(Icons.task, color: AppTheme.primary, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Recently Assigned', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (_recentAssignments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No recent sessions.', style: TextStyle(color: AppTheme.textMuted))),
                          )
                        else
                          ..._recentAssignments.take(5).toList().asMap().entries.map((entry) {
                            final i = entry.key;
                            final a = entry.value as Map<String, dynamic>;
                            final session = a['session'];
                            if (session is! Map<String, dynamic>) return const SizedBox.shrink();
                            final sess = SessionItem.fromJson(session);
                            return InkWell(
                              onTap: () => _navTo(SessionQuizzesScreen(session: sess)),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(sess.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppTheme.primary), overflow: TextOverflow.ellipsis),
                                          if (sess.startTime != null && sess.endTime != null)
                                            Text(
                                              _formatRange(sess.startTime!, sess.endTime!),
                                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 18),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRange(String s, String e) {
    try {
      final ds = DateTime.parse(s.replaceAll(' ', 'T'));
      final de = DateTime.parse(e.replaceAll(' ', 'T'));
      String fmt(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';
      return '${fmt(ds)} → ${fmt(de)}';
    } catch (_) {
      return '';
    }
  }

  String _month(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[(m - 1).clamp(0, 11)];
  }

  void _navTo(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  final VoidCallback onTap;

  const _StatTile({required this.icon, required this.color, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryLight, size: 22),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
