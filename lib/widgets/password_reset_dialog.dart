import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({
    super.key,
    required this.auth,
    this.initialEmail = '',
  });

  final FirebaseAuth auth;
  final String initialEmail;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _loading = false;
  bool _confirmed = false;
  String? _error;

  Future<void> _send() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    var confirmed = false;
    try {
      await widget.auth.sendPasswordResetEmail(email: _email.text.trim());
      confirmed = true;
    } on FirebaseAuthException catch (error) {
      // The response must not disclose whether an address has an account.
      confirmed = error.code == 'user-not-found';
    } catch (_) {
      // Connection/configuration details do not belong in user-facing errors.
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _confirmed = confirmed;
      if (!confirmed) {
        _error = 'No se pudo procesar la solicitud. Intenta nuevamente.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
        title: Text(_confirmed ? 'Revisa tu correo' : 'Recuperar contraseña'),
        content: _confirmed
            ? const Text(
                'Si el correo corresponde a una cuenta, recibirás instrucciones para restablecer tu contraseña.',
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        key: const ValueKey('reset-email'),
                        controller: _email,
                        enabled: !_loading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                        ),
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty) {
                            return 'Ingresa tu correo electrónico.';
                          }
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(email)) {
                            return 'Ingresa un correo electrónico válido.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        actions: _confirmed
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ]
            : [
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: _loading ? null : _send,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Enviar'),
                ),
              ],
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }
}
