import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signup = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_signup) {
        final loggedIn = await Repo.signUp(_email.text.trim(), _password.text, _name.text.trim());
        if (!loggedIn && mounted) {
          setState(() {
            _info = 'Cuenta creada. Revisa tu correo, confirma el email y vuelve aquí para entrar.';
            _signup = false;
          });
        }
      } else {
        await Repo.signIn(_email.text.trim(), _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = Repo.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const _ArcLogo(),
                  const SizedBox(height: 20),
                  const Text('VERDADERO INGENIERO',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  const SizedBox(height: 6),
                  const Text('Dos horas al día. Un examen al día. Hacer del esfuerzo la perfección.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim)),
                  const SizedBox(height: 28),
                  HudCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (_signup) ...[
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('Tu nombre', Icons.person_outline),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe tu nombre' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: _dec('Email', Icons.alternate_email),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Email no válido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _dec('Contraseña', Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            )),
                        validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.red)),
                      ],
                      if (_info != null) ...[
                        const SizedBox(height: 12),
                        Text(_info!, style: const TextStyle(color: AppColors.green)),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        child: _busy
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_signup ? 'Crear cuenta y empezar' : 'Entrar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _signup = !_signup;
                                  _error = null;
                                }),
                        child: Text(_signup ? '¿Ya tienes cuenta? Inicia sesión' : '¿Primera vez? Crea tu cuenta'),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo circular tipo reactor dibujado con widgets.
class _ArcLogo extends StatelessWidget {
  const _ArcLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.arc, width: 3),
          boxShadow: [BoxShadow(color: AppColors.arc.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 2)],
        ),
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.arc.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.arc.withValues(alpha: 0.8), width: 2),
            ),
            child: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.arc, size: 28),
          ),
        ),
      ),
    );
  }
}
