import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.auth});

  final FirebaseAuth? auth;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirmation = true;
  bool _accountCreated = false;
  String? _error;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Ingresa tu correo institucional.';
    if (!RegExp(
      r'^[^\s@]+@tecdesoftware\.edu\.mx$',
      caseSensitive: false,
    ).hasMatch(email)) {
      return 'Usa un correo terminado en @tecdesoftware.edu.mx.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Usa al menos 8 caracteres.';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Incluye al menos una mayúscula.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Incluye al menos una minúscula.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Incluye al menos un número.';
    }
    if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) {
      return 'Incluye al menos un símbolo.';
    }
    return null;
  }

  Future<void> _register() async {
    if (_loading) return;
    if (!_accountCreated && !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!_accountCreated) {
        await _auth.createUserWithEmailAndPassword(
          email: _email.text.trim().toLowerCase(),
          password: _password.text,
        );
        _accountCreated = true;
      }
      // Firebase signs in automatically after registration. Leave no session
      // behind, including when a previous signOut attempt needs retrying.
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _accountCreated
            ? 'La cuenta se creó, pero no se pudo cerrar la sesión. Reintenta para regresar al login.'
            : 'No se pudo completar el registro. Verifica los datos e inténtalo de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading && !_accountCreated,
      child: Scaffold(
        appBar: AppBar(title: const Text('Crear cuenta')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Regístrate con tu correo institucional.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('signup-email'),
                    controller: _email,
                    enabled: !_loading && !_accountCreated,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: _decoration('Correo institucional'),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('signup-password'),
                    controller: _password,
                    enabled: !_loading && !_accountCreated,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _decoration(
                      'Contraseña',
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        onPressed: _loading || _accountCreated
                            ? null
                            : () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('signup-confirm-password'),
                    controller: _confirmation,
                    enabled: !_loading && !_accountCreated,
                    obscureText: _obscureConfirmation,
                    decoration: _decoration(
                      'Confirmar contraseña',
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmation
                            ? 'Mostrar confirmación'
                            : 'Ocultar confirmación',
                        onPressed: _loading || _accountCreated
                            ? null
                            : () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                        icon: Icon(
                          _obscureConfirmation
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Confirma tu contraseña.';
                      if (value != _password.text)
                        return 'Las contraseñas no coinciden.';
                      return null;
                    },
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    key: const ValueKey('signup-submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 139, 45),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _accountCreated
                                ? 'Cerrar sesión y volver al login'
                                : 'Crear cuenta',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }
}
