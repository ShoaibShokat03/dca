import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/live_stream.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'video_player_screen.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  bool _loading = true;
  String? _error;
  LiveStream? _stream;
  Timer? _ticker;
  String _statusText = '';
  String _remainingText = '';
  Color _statusColor = AppTheme.textMuted;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.liveStream);
      if (res.success && res.data is Map<String, dynamic>) {
        _stream = LiveStream.fromJson(res.data as Map<String, dynamic>);
        _startTicker();
      } else if (res.success && res.data == null) {
        _stream = null;
      } else {
        _error = res.message;
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    if (_stream == null || !mounted) return;
    final s = _stream!;
    final start = s.startTime != null ? DateTime.tryParse(s.startTime!.replaceAll(' ', 'T')) : null;
    final end = s.endTime != null ? DateTime.tryParse(s.endTime!.replaceAll(' ', 'T')) : null;
    if (start == null || end == null) return;
    final now = DateTime.now();
    if (now.isBefore(start)) {
      final secs = start.difference(now).inSeconds;
      _statusText = 'Scheduled';
      _remainingText = _fmt(secs);
      _statusColor = AppTheme.warning;
    } else if (now.isBefore(end)) {
      final secs = end.difference(now).inSeconds;
      _statusText = 'Live Now';
      _remainingText = _fmt(secs);
      _statusColor = AppTheme.success;
    } else {
      _statusText = 'Ended';
      _remainingText = 'Stream ended';
      _statusColor = AppTheme.danger;
      _ticker?.cancel();
    }
    if (mounted) setState(() {});
  }

  String _fmt(int s) {
    if (s <= 0) return '0s';
    final d = s ~/ 86400;
    final h = (s % 86400) ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    var t = '';
    if (d > 0) t += '${d}d ';
    if (h > 0) t += '${h}h ';
    if (m > 0) t += '${m}m ';
    t += '${sec}s';
    return t;
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                title: 'Live Stream',
                subtitle: _stream != null ? _statusText : 'No stream scheduled',
                icon: Icons.live_tv,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _stream == null
                          ? const EmptyView(icon: Icons.satellite, title: 'No Stream', message: 'No live stream scheduled at the moment.')
                          : _build(_stream!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build(LiveStream s) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status tile
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(_statusText, style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700, fontSize: 14)),
                      const Spacer(),
                      Text(_remainingText, style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  if (s.title != null) ...[
                    const SizedBox(height: 12),
                    Text(s.title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ],
                  if (s.description != null && s.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(s.description!, style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                  ],
                  const SizedBox(height: 12),
                  if (s.startTime != null) Text('Starts: ${s.startTime}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  if (s.endTime != null) Text('Ends: ${s.endTime}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action button
            if (s.streamUrl != null && s.streamUrl!.isNotEmpty) ...[
              if (s.streamType == 'youtube' || (s.streamUrl!.contains('youtube.com') || s.streamUrl!.contains('youtu.be')))
                ElevatedButton.icon(
                  onPressed: () => _openExternal(s.streamUrl!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open YouTube Stream'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0000), padding: const EdgeInsets.symmetric(vertical: 14)),
                )
              else if (s.streamType == 'zoom')
                ElevatedButton.icon(
                  onPressed: () => _openExternal(s.streamUrl!),
                  icon: const Icon(Icons.video_call),
                  label: const Text('Join Zoom Meeting'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D8CFF), padding: const EdgeInsets.symmetric(vertical: 14)),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(url: s.streamUrl!, title: s.title ?? 'Live Stream'),
                  )),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch Stream'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
