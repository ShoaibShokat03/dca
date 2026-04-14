import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'email': TextEditingController(),
    'password': TextEditingController(),
    'full_name': TextEditingController(),
    'father_name': TextEditingController(),
    'cnic': TextEditingController(),
    'number': TextEditingController(),
    'city': TextEditingController(),
    'uni': TextEditingController(),
    'workplace': TextEditingController(),
  };
  String _gender = 'male';
  bool _showPassword = false;

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final fields = <String, String>{};
    _controllers.forEach((k, c) => fields[k] = c.text.trim());
    fields['gender'] = _gender;
    final ok = await auth.signup(fields);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      showSnack(context, auth.error ?? 'Signup failed', error: true);
    }
  }

  Widget _buildField(String name, String label, {bool required = true, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[name],
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label + (required ? ' *' : '')),
        validator: (v) => (required && (v == null || v.trim().isEmpty)) ? '$label is required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField('full_name', 'Full Name'),
                _buildField('father_name', "Father's Name"),
                _buildField('email', 'Email', keyboard: TextInputType.emailAddress),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _controllers['password'],
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Password must be 6+ chars' : null,
                  ),
                ),
                _buildField('cnic', 'CNIC'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender *'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'male'),
                  ),
                ),
                _buildField('number', 'Phone Number', required: false, keyboard: TextInputType.phone),
                _buildField('city', 'City', required: false),
                _buildField('uni', 'University', required: false),
                _buildField('workplace', 'Workplace', required: false),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _submit,
                    child: auth.loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
