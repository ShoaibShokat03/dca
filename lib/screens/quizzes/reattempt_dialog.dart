import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/quiz.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class ReattemptDialog extends StatefulWidget {
  final Quiz quiz;
  const ReattemptDialog({super.key, required this.quiz});

  @override
  State<ReattemptDialog> createState() => _ReattemptDialogState();
}

class _ReattemptDialogState extends State<ReattemptDialog> {
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final res = await ApiService.post(ApiConfig.reattempts, body: {'quiz_id': widget.quiz.id, 'reason': _ctrl.text.trim()});
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, res.message, error: !res.success);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(children: [
              Icon(Icons.refresh, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Request Re-Attempt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Reason', hintText: 'Why do you need a re-attempt?'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
