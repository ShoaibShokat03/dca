import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;
  String? _error;

  // Edit mode controllers
  bool _editing = false;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _ctrls = {
    'full_name': TextEditingController(),
    'father_name': TextEditingController(),
    'cnic': TextEditingController(),
    'number': TextEditingController(),
    'city': TextEditingController(),
    'uni': TextEditingController(),
    'workplace': TextEditingController(),
    'new_password': TextEditingController(),
  };
  String _gender = 'male';
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get(ApiConfig.profile);
      if (res.success && res.data is Map<String, dynamic>) {
        final user = User.fromJson(res.data as Map<String, dynamic>);
        if (mounted) {
          context.read<AuthProvider>().updateUser(user);
          _ctrls['full_name']!.text = user.fullName ?? '';
          _ctrls['father_name']!.text = user.fatherName ?? '';
          _ctrls['cnic']!.text = user.cnic ?? '';
          _ctrls['number']!.text = user.number ?? '';
          _ctrls['city']!.text = user.city ?? '';
          _ctrls['uni']!.text = user.uni ?? '';
          _ctrls['workplace']!.text = user.workplace ?? '';
          _gender = user.gender ?? 'male';
        }
      } else {
        _error = res.message;
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{};
      _ctrls.forEach((k, c) {
        if (k == 'new_password' && c.text.isEmpty) return;
        body[k] = c.text.trim();
      });
      body['gender'] = _gender;
      final res = await ApiService.post(ApiConfig.profileUpdate, body: body);
      if (mounted) {
        showSnack(context, res.message.isNotEmpty ? res.message : (res.success ? 'Updated' : 'Failed'), error: !res.success);
        if (res.success) {
          setState(() => _editing = false);
          await _load();
        }
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to log in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: PageHeader(
                title: user?.displayName ?? 'Profile',
                subtitle: user?.email,
                icon: Icons.person,
                actions: [
                  IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.primary,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  AppCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(children: [
                                          const Text('Personal Info', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                          const Spacer(),
                                          TextButton.icon(
                                            onPressed: () => setState(() => _editing = !_editing),
                                            icon: Icon(_editing ? Icons.close : Icons.edit, size: 16),
                                            label: Text(_editing ? 'Cancel' : 'Edit'),
                                          ),
                                        ]),
                                        const Divider(height: 14),
                                        if (_editing) ..._buildEditForm() else ..._buildReadonly(user),
                                        if (_editing) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(onPressed: _save, child: const Text('Save Changes')),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReadonly(User? user) {
    if (user == null) return [const Text('No user data')];
    return [
      _row('Full Name', user.fullName),
      _row("Father's Name", user.fatherName),
      _row('CNIC', user.cnic),
      _row('Gender', user.gender),
      _row('Phone', user.number),
      _row('City', user.city),
      _row('University', user.uni),
      _row('Workplace', user.workplace),
      _row('Fee Status', user.feePaid),
    ];
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value == null || value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 13, color: AppTheme.textBody, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  List<Widget> _buildEditForm() {
    return [
      _field('full_name', 'Full Name'),
      _field('father_name', "Father's Name"),
      _field('cnic', 'CNIC'),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          value: _gender,
          decoration: const InputDecoration(labelText: 'Gender'),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => _gender = v ?? 'male'),
        ),
      ),
      _field('number', 'Phone', keyboard: TextInputType.phone),
      _field('city', 'City'),
      _field('uni', 'University'),
      _field('workplace', 'Workplace'),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: _ctrls['new_password'],
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'New Password (leave blank to keep current)',
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _field(String key, String label, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _ctrls[key],
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
