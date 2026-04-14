import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/news.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _loading = true;
  String? _error;
  List<NewsItem> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.news);
      if (res.success && res.data is List) {
        _items = (res.data as List).map((n) => NewsItem.fromJson(n as Map<String, dynamic>)).toList();
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
                title: 'News & Updates',
                subtitle: '${_items.length} announcements',
                icon: Icons.campaign,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _items.isEmpty
                          ? const EmptyView(icon: Icons.notifications_off, title: 'No news', message: 'Nothing to show right now.')
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppTheme.primary,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final n = _items[i];
                                  return AppCard(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(n.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                        if (n.description != null && n.description!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(n.description!, style: const TextStyle(fontSize: 13, color: AppTheme.textBody, height: 1.4)),
                                        ],
                                        if (n.createdAt != null) ...[
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            const Icon(Icons.access_time, size: 11, color: AppTheme.textMuted),
                                            const SizedBox(width: 4),
                                            Text(n.createdAt!, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                                          ]),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
