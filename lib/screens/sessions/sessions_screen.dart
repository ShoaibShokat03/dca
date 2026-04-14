import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/session.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'session_quizzes_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<SessionItem> _assigned = [];
  List<SessionItem> _other = [];
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.sessions);
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        _assigned = ((d['assigned_sessions'] as List?) ?? []).map((s) => SessionItem.fromJson(s as Map<String, dynamic>)).toList();
        _other = ((d['other_sessions'] as List?) ?? []).map((s) => SessionItem.fromJson(s as Map<String, dynamic>)).toList();
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: PageHeader(
                title: 'My Sessions',
                subtitle: '${_assigned.length} assigned, ${_other.length} other',
                icon: Icons.calendar_month,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.borderLight, width: 1.5),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textMuted,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Assigned (${_assigned.length})'),
                  Tab(text: 'Other (${_other.length})'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _list(_assigned, true),
                            _list(_other, false),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<SessionItem> items, bool isAssigned) {
    if (items.isEmpty) {
      return const EmptyView(icon: Icons.inbox_outlined, title: 'No sessions', message: 'Nothing here yet.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, i) {
          final s = items[i];
          return AppCard(
            onTap: isAssigned ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionQuizzesScreen(session: s))) : null,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary), overflow: TextOverflow.ellipsis),
                      if (s.startTime != null && s.endTime != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.event, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Expanded(child: Text(_range(s), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
                        ]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isAssigned)
                  s.isDemo ? const StatusBadge.success(text: 'Demo') : const StatusBadge.info(text: 'Premium')
                else
                  StatusBadge(text: 'Not Assigned', color: AppTheme.textMuted, background: const Color(0xFFF8F9FA)),
                if (isAssigned) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.chevron_right, color: AppTheme.textLight, size: 18)),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: items.length,
      ),
    );
  }

  String _range(SessionItem s) {
    try {
      final ds = DateTime.parse(s.startTime!.replaceAll(' ', 'T'));
      final de = DateTime.parse(s.endTime!.replaceAll(' ', 'T'));
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${ds.day} ${months[ds.month-1]} ${ds.year} → ${de.day} ${months[de.month-1]} ${de.year}';
    } catch (_) { return ''; }
  }
}
