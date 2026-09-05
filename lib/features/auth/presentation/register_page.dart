import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  final Map<String, String> _fieldErrors = {};

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final email = _email.text.trim();
    final phone = _phone.text.trim();

    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least an email address or phone number.'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _fieldErrors.clear();
    });

    try {
      await ref.read(authControllerProvider.notifier).register(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            displayName: _username.text.trim(),
            email: email,
            phone: phone,
            password: _password.text,
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;

      if (error is ApiException && error.fieldErrors.isNotEmpty) {
        setState(() => _fieldErrors.addAll(error.fieldErrors));
      }

      final message = ref.read(authControllerProvider).error ??
          'Unable to create your account. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _fieldKey(String label) {
    switch (label) {
      case 'First name':
        return 'first_name';
      case 'Last name':
        return 'last_name';
      case 'Username':
        return 'display_name';
      case 'Email':
        return 'email';
      case 'Phone':
        return 'phone';
      case 'Password':
        return 'password';
      default:
        return label;
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscure = false,
    bool required = true,
  }) {
    IconData icon = Icons.person_outline;
    if (label == 'Email') icon = Icons.email_outlined;
    if (label == 'Phone') icon = Icons.phone_outlined;
    if (label == 'Password') icon = Icons.lock_outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure && _obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: _fieldErrors[_fieldKey(label)],
          suffixIcon: obscure
              ? IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                )
              : null,
        ),
        validator: (value) {
          final trimmed = value?.trim() ?? '';

          if (required && trimmed.isEmpty) {
            return '$label is required';
          }

          if (!required && trimmed.isEmpty) {
            return null;
          }

          if (label == 'Username' && trimmed.length < 3) {
            return 'Username must be at least 3 characters';
          }

          if (label == 'Username' && trimmed.contains(' ')) {
            return 'Username cannot contain spaces';
          }

          if (label == 'Email' &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
            return 'Enter a valid email address';
          }

          if (label == 'Phone' &&
              !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(trimmed)) {
            return 'Use international format, e.g. +254712345678';
          }

          if (label == 'Password' && value != null && value.length < 8) {
            return 'Use at least 8 characters';
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join Hapa',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help your community stay informed about what is happening nearby.',
                    ),
                    const SizedBox(height: 28),
                    _field(_first, 'First name'),
                    _field(_last, 'Last name'),
                    _field(_username, 'Username'),
                    _field(
                      _email,
                      'Email',
                      keyboardType: TextInputType.emailAddress,
                      required: false,
                    ),
                    _field(
                      _phone,
                      'Phone',
                      keyboardType: TextInputType.phone,
                      required: false,
                    ),
                    _field(_password, 'Password', obscure: true),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
