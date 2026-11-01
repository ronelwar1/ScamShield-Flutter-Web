import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../widgets/shield_logo.dart';

/// Sign-in / register form. UI ONLY: there is no account backend yet, and the screen says so plainly.
/// ScamShield works fully as a guest.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.startOnRegister = false});
  final bool startOnRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  late bool _register = widget.startOnRegister;
  bool _obscure = true;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _notice = 'Enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _notice = 'Password must be at least 8 characters.');
      return;
    }
    // Nothing is stored or sent: accounts are not implemented yet.
    setState(() => _notice =
        'Accounts are not connected yet, so nothing was saved or sent. You can use every ScamShield feature as a guest.');
    _password.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primaryDark,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SoftCard(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: ShieldLogo(size: 64)),
                    const SizedBox(height: 16),
                    Text(
                      _register ? 'Create your account' : 'Welcome back!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _register ? 'Register with your email to get started.' : 'Sign in with your email to continue.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 14.5),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline_rounded)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: _register ? const [AutofillHints.newPassword] : const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    if (_notice != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.sunshineSoft, borderRadius: BorderRadius.circular(14)),
                        child: Text(_notice!, style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.45)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_register ? 'Create account' : 'Sign in', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(_register ? 'Already have an account?' : 'New here?', style: const TextStyle(color: AppColors.mutedText)),
                        TextButton(
                          onPressed: () => setState(() {
                            _register = !_register;
                            _notice = null;
                          }),
                          child: Text(_register ? 'Sign in' : 'Register', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Continue as guest'),
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
