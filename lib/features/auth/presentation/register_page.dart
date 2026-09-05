import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import '../../../core/network/api_exception.dart';

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

  bool _loading = false;
  bool _obscure = true;
  final Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    for (final controller in [_first, _last, _username, _email, _phone, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_email.text.trim().isEmpty && _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least an email or phone number.')),
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
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
          );

      if (mounted) Navigator.of(context).pop();
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    TextInputType? type,
    bool secret = false,
    bool required = true,
  }) {
    final prefixIcon = secret
        ? Icons.lock_outline
        : label == 'Email'
            ? Icons.email_outlined
            : label == 'Phone'
                ? Icons.phone_outlined
                : Icons.person_outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: secret && _obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: secret
              ? IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                )
              : null,
          errorText: _fieldErrors[_fieldKey(label)],
        ),
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (required && trimmed.isEmpty) {
            return '$label is required';
          }
          if (!required && trimmed.isEmpty) return null;
          if (label == 'Username' && value.trim().length < 3) {
            return 'Username must be at least 3 characters';
          }
          if (label == 'Username' && value.trim().contains(' ')) {
            return 'Username cannot contain spaces';
          }
          if (label == 'Email' && !RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+
            return 'Enter a valid email';
          }
          if (label == 'Phone' && !RegExp(r'^\\+[1-9][0-9]{7,14}
            return 'Use at least 8 characters';
          }
          return null;
        },
      ),
    );
  }

  String _fieldKey(String label) => switch (label) {
        'First name' => 'first_name',
        'Last name' => 'last_name',
        'Username' => 'display_name',
        'Email' => 'email',
        'Phone' => 'phone',
        'Password' => 'password',
        _ => label,
      };

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
                    field(_first, 'First name'),
                    field(_last, 'Last name'),
                    field(_username, 'Username'),
                    field(
                      _email,
                      'Email',
                      type: TextInputType.emailAddress,
                      required: false,
                    ),
                    field(
                      _phone,
                      'Phone',
                      type: TextInputType.phone,
                      required: false,
                    ),
                    field(_password, 'Password', secret: true),
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
).hasMatch(trimmed)) {
            return 'Enter a valid email';
          }
          if (secret && value.length < 8) {
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
                    field(_first, 'First name'),
                    field(_last, 'Last name'),
                    field(_username, 'Username'),
                    field(
                      _email,
                      'Email',
                      type: TextInputType.emailAddress,
                    ),
                    field(
                      _phone,
                      'Phone',
                      type: TextInputType.phone,
                    ),
                    field(_password, 'Password', secret: true),
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
).hasMatch(trimmed)) {
            return 'Use international format, e.g. +254712345678';
          }
          if (secret && value.length < 8) {
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
                    field(_first, 'First name'),
                    field(_last, 'Last name'),
                    field(_username, 'Username'),
                    field(
                      _email,
                      'Email',
                      type: TextInputType.emailAddress,
                    ),
                    field(
                      _phone,
                      'Phone',
                      type: TextInputType.phone,
                    ),
                    field(_password, 'Password', secret: true),
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
).hasMatch(trimmed)) {
            return 'Enter a valid email';
          }
          if (secret && value.length < 8) {
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
                    field(_first, 'First name'),
                    field(_last, 'Last name'),
                    field(_username, 'Username'),
                    field(
                      _email,
                      'Email',
                      type: TextInputType.emailAddress,
                    ),
                    field(
                      _phone,
                      'Phone',
                      type: TextInputType.phone,
                    ),
                    field(_password, 'Password', secret: true),
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
